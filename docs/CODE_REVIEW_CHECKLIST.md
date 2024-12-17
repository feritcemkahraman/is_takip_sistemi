# Code Review Checklist

## Genel

- [ ] Kod style guide'a uygun mu?
- [ ] Değişken ve fonksiyon isimleri anlamlı mı?
- [ ] Gereksiz kod tekrarı var mı?
- [ ] TODO yorumları uygun şekilde işaretlenmiş mi?
- [ ] Dökümantasyon güncel mi?

## Model Katmanı

- [ ] Tüm gerekli validasyonlar eklenmiş mi?
- [ ] JSON serialization/deserialization testleri var mı?
- [ ] Status geçişleri doğru tanımlanmış mı?
- [ ] Immutability prensipleri uygulanmış mı?
- [ ] toString(), equals() ve hashCode() metodları implement edilmiş mi?

## Servis Katmanı

- [ ] Error handling yeterli mi?
- [ ] Transaction yönetimi doğru mu?
- [ ] Batch operations optimize edilmiş mi?
- [ ] Retry mekanizmaları uygun mu?
- [ ] Logging yeterli seviyede mi?

## Firebase

- [ ] Security rules test edilmiş mi?
- [ ] Offline support configure edilmiş mi?
- [ ] Cache stratejileri uygun mu?
- [ ] Query optimizasyonları yapılmış mı?
- [ ] Batch size limitleri uygun mu?

## Testler

- [ ] Unit test coverage yeterli mi? (>80%)
- [ ] Integration testler eklenmiş mi?
- [ ] Edge case'ler test edilmiş mi?
- [ ] Mock'lar doğru kullanılmış mı?
- [ ] Test dökümantasyonu yeterli mi?

## Performance

- [ ] Network çağrıları optimize edilmiş mi?
- [ ] Memory leak riski var mı?
- [ ] Cache kullanımı uygun mu?
- [ ] Batch operations kullanılmış mı?
- [ ] Query performansı optimize edilmiş mi?

## Security

- [ ] Input validation yapılmış mı?
- [ ] Authentication kontrolleri var mı?
- [ ] Authorization kuralları doğru mu?
- [ ] Sensitive data korunuyor mu?
- [ ] Error mesajları güvenli mi?

## UI/UX

- [ ] Error state'leri handle edilmiş mi?
- [ ] Loading state'leri uygun mu?
- [ ] Responsive design prensipleri uygulanmış mı?
- [ ] Accessibility standartlarına uyulmuş mu?
- [ ] User feedback mekanizmaları var mı?

## Dependencies

- [ ] Yeni dependency'ler gerekli mi?
- [ ] Version conflict'leri çözülmüş mü?
- [ ] License uyumlulukları kontrol edilmiş mi?
- [ ] Breaking change risk'leri değerlendirilmiş mi?
- [ ] Dependency size'ları kabul edilebilir mi?

## Documentation

- [ ] API documentation güncel mi?
- [ ] README güncellenmiş mi?
- [ ] Change log eklenmiş mi?
- [ ] Migration guide gerekli mi?
- [ ] Architecture decision records güncel mi?
