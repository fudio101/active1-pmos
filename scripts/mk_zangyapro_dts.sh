#!/bin/bash
set -e
K=~/linux-sdm660/arch/arm64/boot/dts/qcom
cd "$K"
cp sdm660-xiaomi-jasmine.dts sdm660-vsmart-zangyapro.dts
# doi dinh danh
sed -i 's|model = "Xiaomi Mi A2";|model = "Vsmart Active 1 (zangyapro)";|' sdm660-vsmart-zangyapro.dts
sed -i 's|compatible = "xiaomi,jasmine", "qcom,sdm660";|compatible = "vsmart,active1", "qcom,sdm660";|' sdm660-vsmart-zangyapro.dts
# them vao Makefile (sau dong jasmine)
if ! grep -q 'sdm660-vsmart-zangyapro.dtb' Makefile; then
  sed -i '/sdm660-xiaomi-jasmine.dtb/a dtb-$(CONFIG_ARCH_QCOM) += sdm660-vsmart-zangyapro.dtb' Makefile
fi
echo "=== dts dinh danh moi ==="
grep -nE 'model =|compatible =' sdm660-vsmart-zangyapro.dts | head -2
echo "=== Makefile entry ==="
grep -n 'zangyapro' Makefile
echo "=== file ton tai ==="
ls -la sdm660-vsmart-zangyapro.dts
echo DONE
