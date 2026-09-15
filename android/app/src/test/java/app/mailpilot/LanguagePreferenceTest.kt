package app.mailpilot

import app.mailpilot.data.AppLanguage
import app.mailpilot.data.UserSettings
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], application = android.app.Application::class)
class LanguagePreferenceTest {
    @Test fun oldSettingsDefaultToSimplifiedChinese() {
        assertEquals("zh", UserSettings().appLanguage)
        assertEquals("zh", AppLanguage.normalize(null))
        assertEquals("zh", AppLanguage.normalize(""))
    }
    @Test fun supportedLanguagesRoundTripAndUnknownValuesFallBack() {
        assertEquals(setOf("zh", "zh_Hant", "en", "ja", "ko", "es", "fr", "de"), AppLanguage.supported)
        AppLanguage.supported.forEach { assertEquals(it, AppLanguage.normalize(it)) }
        listOf("system", "../en", "xx", "en_US", "null").forEach { assertEquals("zh", AppLanguage.normalize(it)) }
    }
    @Test fun changingUiLanguagePreservesOtherPreferences() {
        val previous=UserSettings(accountId="a",textModelId="m",visionModelId="v",theme="dark",syncMinutes=1440,fastCompression=false)
        val next=previous.copy(appLanguage="de")
        assertEquals(previous,next.copy(appLanguage="zh"))
        assertEquals(previous.speech,next.speech)
        assertEquals(previous.search,next.search)
    }
}
