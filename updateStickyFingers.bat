for %%x in (_retail_ _classic_) do (
  echo Installing for %%x
  copy /y C:\Users\Hellvector\Documents\GitHub\StickyFingers\README.txt "C:\Program Files (x86)\World of Warcraft\%%x\Interface\AddOns\StickyFingers\README.txt"
  copy /y C:\Users\Hellvector\Documents\GitHub\StickyFingers\StickyFingers.lua "C:\Program Files (x86)\World of Warcraft\%%x\Interface\AddOns\StickyFingers\StickyFingers.lua"
  if %%x == _retail_ (
    copy /y C:\Users\Hellvector\Documents\GitHub\StickyFingers\StickyFingersRetail.toc "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\StickyFingers\StickyFingers.toc"
  ) else if %%x == _classic_ (
    copy /y C:\Users\Hellvector\Documents\GitHub\StickyFingers\StickyFingersClassic.toc "C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\StickyFingers\StickyFingers.toc"
  )
)
