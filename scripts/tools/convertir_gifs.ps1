# Convertit chaque GIF anime depose par Mike (sprites de creatures,
# decor du Hub, etc.) en planche de sprites PNG (une rangee de N frames
# carrees, cote a cote) que Godot peut charger nativement (Godot ne lit
# pas les GIF animes -- voir assets/creatures/LISEZ-MOI.txt pour le
# detail du choix).
#
# Appele automatiquement par lancer_jeu.bat avant chaque lancement du
# jeu -- aucune action manuelle requise de la part de Mike au-dela de
# deposer le .gif. Ne reconvertit que les fichiers nouveaux/modifies
# (compare les dates de modification .gif vs .png).
#
# Chaque frame du GIF source est centree sur un canevas carre (cote =
# la plus grande dimension du GIF), avec un fond transparent, avant
# d'etre placee dans la planche -- ainsi la largeur totale de la
# planche divisee par sa hauteur donne toujours le nombre de frames
# exact, sans fichier de metadonnees separe (SpriteUtil.compter_frames()
# cote Godot).
#
# Garde-fou largeur GPU (trouve avec un GIF a 86 frames de 320x320 :
# planche de 27520x320, largeur qui depasse la limite materielle d'une
# texture 2D -- generalement 8192 ou 16384px selon le GPU/renderer --
# et s'affiche en boite noire dans le jeu au lieu de planter a
# l'import). Si la planche depasserait $LARGEUR_MAX_SURE, on REDUIT le
# nombre de frames (echantillonnage regulier, pas juste les N
# premieres) pour rester dans une limite sure sur toutes les machines,
# plutot que de risquer une texture corrompue.
$LARGEUR_MAX_SURE = 8192

Add-Type -AssemblyName System.Drawing

$dossiers = @(
    (Join-Path $PSScriptRoot "..\..\assets\creatures"),
    (Join-Path $PSScriptRoot "..\..\assets\ui\hub")
)

foreach ($dossier in $dossiers) {
    $gifs = Get-ChildItem -Path $dossier -Filter "*.gif" -ErrorAction SilentlyContinue
    foreach ($gif in $gifs) {
        $pngPath = [System.IO.Path]::ChangeExtension($gif.FullName, "png")
        $pngExiste = Test-Path $pngPath
        if ($pngExiste -and (Get-Item $pngPath).LastWriteTimeUtc -ge $gif.LastWriteTimeUtc) {
            continue
        }

        try {
            $image = [System.Drawing.Image]::FromFile($gif.FullName)
            $dimension = New-Object System.Drawing.Imaging.FrameDimension($image.FrameDimensionsList[0])
            $nbFrames = $image.GetFrameCount($dimension)
            $cote = [Math]::Max($image.Width, $image.Height)

            # Echantillonnage regulier des frames source si la planche
            # depasserait la largeur GPU sure (voir commentaire d'entete) --
            # jamais juste les N premieres frames, pour garder une
            # animation qui couvre toute la duree d'origine.
            $indicesFrames = 0..($nbFrames - 1)
            $nbFramesReel = $nbFrames
            if (($cote * $nbFrames) -gt $LARGEUR_MAX_SURE) {
                $nbFramesReel = [Math]::Max(1, [Math]::Floor($LARGEUR_MAX_SURE / $cote))
                $indicesFrames = 0..($nbFramesReel - 1) | ForEach-Object { [Math]::Floor($_ * $nbFrames / $nbFramesReel) }
            }

            $feuille = New-Object System.Drawing.Bitmap ($cote * $nbFramesReel), $cote
            $g = [System.Drawing.Graphics]::FromImage($feuille)
            $g.Clear([System.Drawing.Color]::Transparent)

            for ($i = 0; $i -lt $nbFramesReel; $i++) {
                $image.SelectActiveFrame($dimension, $indicesFrames[$i]) | Out-Null
                $decalageX = $i * $cote + [Math]::Floor(($cote - $image.Width) / 2)
                $decalageY = [Math]::Floor(($cote - $image.Height) / 2)
                $g.DrawImage($image, $decalageX, $decalageY, $image.Width, $image.Height)
            }

            $g.Dispose()
            $feuille.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $feuille.Dispose()
            $image.Dispose()
            if ($nbFramesReel -lt $nbFrames) {
                Write-Output "Converti : $($gif.Name) -> $([System.IO.Path]::GetFileName($pngPath)) ($nbFramesReel frames sur $nbFrames d'origine -- reduit pour rester sous la largeur GPU sure de $LARGEUR_MAX_SURE px, $cote x $cote par frame)"
            } else {
                Write-Output "Converti : $($gif.Name) -> $([System.IO.Path]::GetFileName($pngPath)) ($nbFramesReel frames, $cote x $cote par frame)"
            }
        } catch {
            Write-Output "ECHEC conversion $($gif.Name) : $($_.Exception.Message)"
        }
    }
}
