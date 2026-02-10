/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Batlin
import Files
import ShellOut
import Codextended
import BatlinCLICore

let cli = CLI(
    batlinRepositoryURL: URL(
        string: "https://github.com/MichaelJBerk/Batlin-Publish"
    )!,
    batlinBranch: "main"
)

do {
    try cli.run()
} catch {
    fputs("❌ \(error)\n", stderr)
    exit(1)
}
