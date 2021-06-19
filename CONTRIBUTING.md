# RedCat Needs You! :point_up:

Hey there! Glad that your willingness to contribute to RedCat brought you here.

The first step to contributing to this project is to have a look at the [discussions](https://github.com/AnarchoSystems/RedCat/discussions) section.

If you're just curious about the project, the *general* category will be for you. If you have used RedCat in an open source project and want to let us know, use the *show and tell* category. You can also ask us to feature your project as an example project in our Readme - we only want you to keep your project up to date (in terms of RedCat versions) in return.

If you think you have an idea for a new feature or found a bug, please let us know via the *ideas* or the *bugs* section in the discussions before investing any serious effort in a pull request. Trivial PRs (like corrected typos in the documentation or the Readme) are likely to be accepted right away.

# PRs

Speaking of PRs: If you have decided that you want to add a feature or fix a bug, please open the pull request early in the process and update it at a meaningful frequency. We consider PRs an iterative and interactive process. That way, we minimize surprises for everyone.

PRs have a significantly better chance to be accepted, if they don't break the API. If you add new features, please do your best to comply with the following guidelines:

- If there are any implementation invariants that can't be proven by the compiler, do not ```fatalerror```. Instead, do your best to still return something meaningful and print a message to the console with the following format:

*RedCat: <Description of broken invariant>. Please file a bug report.\nIf your app works fine otherwise, you can silence this warning by setting internalFlags.<Your flag that will silence that warning> to <value> in the environment or by compiling in release mode.*

- Make sure that reducers can be discovered from the proper namespace (```Reducers```).

- Use static features over dynamic features where meaningfully possible.

- Don't publicly expose things that are better kept private. If some feature that is not designed for the public needs to be public for technical reasons, name it with a leading underscore.

# That's It!

Happy coding!

PS contributions in form of artwork are also welcome. I'd be glad to have a red cat icon (for the readme) and a red cat in the "uncle sam needs you" pose to replace the :point_up: emoji at the top of this document.
