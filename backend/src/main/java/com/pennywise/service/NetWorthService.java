package com.pennywise.service;

import com.pennywise.dto.*;
import com.pennywise.entity.Asset;
import com.pennywise.entity.Liability;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.AssetRepository;
import com.pennywise.repository.LiabilityRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
public class NetWorthService {

    private final AssetRepository assetRepository;
    private final LiabilityRepository liabilityRepository;
    private final CurrentUserProvider currentUserProvider;

    public NetWorthService(AssetRepository assetRepository,
                           LiabilityRepository liabilityRepository,
                           CurrentUserProvider currentUserProvider) {
        this.assetRepository = assetRepository;
        this.liabilityRepository = liabilityRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public NetWorthSummaryDto getSummary() {
        UUID userId = currentUserProvider.get().getId();
        List<AssetDto> assets = assetRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().map(this::toAssetDto).toList();
        List<LiabilityDto> liabilities = liabilityRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().map(this::toLiabilityDto).toList();

        BigDecimal totalAssets = assets.stream()
                .map(AssetDto::getValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalLiabilities = liabilities.stream()
                .map(LiabilityDto::getOutstanding)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return NetWorthSummaryDto.builder()
                .totalAssets(totalAssets)
                .totalLiabilities(totalLiabilities)
                .netWorth(totalAssets.subtract(totalLiabilities))
                .assets(assets)
                .liabilities(liabilities)
                .build();
    }

    @Transactional
    public AssetDto createAsset(AssetCreateRequest req) {
        User user = currentUserProvider.get();
        Asset asset = new Asset();
        asset.setUserId(user.getId());
        asset.setAssetType(req.getAssetType());
        asset.setName(req.getName());
        asset.setValue(req.getValue());
        asset.setAsOfDate(req.getAsOfDate() != null ? req.getAsOfDate() : LocalDate.now());
        return toAssetDto(assetRepository.save(asset));
    }

    @Transactional
    public void deleteAsset(UUID id) {
        UUID userId = currentUserProvider.get().getId();
        Asset asset = assetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asset not found"));
        if (!asset.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Asset not found");
        }
        assetRepository.delete(asset);
    }

    @Transactional
    public LiabilityDto createLiability(LiabilityCreateRequest req) {
        User user = currentUserProvider.get();
        Liability liability = new Liability();
        liability.setUserId(user.getId());
        liability.setLiabilityType(req.getLiabilityType());
        liability.setName(req.getName());
        liability.setOutstanding(req.getOutstanding());
        liability.setMonthlyEmi(req.getMonthlyEmi());
        liability.setInterestRate(req.getInterestRate());
        liability.setAsOfDate(req.getAsOfDate() != null ? req.getAsOfDate() : LocalDate.now());
        return toLiabilityDto(liabilityRepository.save(liability));
    }

    @Transactional
    public void deleteLiability(UUID id) {
        UUID userId = currentUserProvider.get().getId();
        Liability liability = liabilityRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Liability not found"));
        if (!liability.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Liability not found");
        }
        liabilityRepository.delete(liability);
    }

    private AssetDto toAssetDto(Asset a) {
        return AssetDto.builder()
                .id(a.getId())
                .assetType(a.getAssetType())
                .name(a.getName())
                .value(a.getValue())
                .asOfDate(a.getAsOfDate())
                .build();
    }

    private LiabilityDto toLiabilityDto(Liability l) {
        return LiabilityDto.builder()
                .id(l.getId())
                .liabilityType(l.getLiabilityType())
                .name(l.getName())
                .outstanding(l.getOutstanding())
                .monthlyEmi(l.getMonthlyEmi())
                .interestRate(l.getInterestRate())
                .asOfDate(l.getAsOfDate())
                .build();
    }
}
