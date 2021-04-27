# Contributing
We generally create issues in GitHub before contributing code. This helps front-load the conversation before the code. By creating an issue first, it creates an opportunity to bounce our ideas off each other to see what's feasible and what ways to approach the issue.

By contrast, starting with a pull request makes it more difficult to revisit the approach. Many PRs are treated as mostly done and shouldn't need much work to get merged. Nobody wants to receive PR feedback that says "start over" or "closing: won't merge." That's discouraging to everyone, and we can avoid those situations if we have the discussion together earlier in the development process. It might be a mental switch for you to start the discussion earlier, but it makes us all more productive and and our rules more effective.

### What a good issue looks like

We have a few types of issue templates to [choose from](https://github.com/Secure-Compliance-Solutions-LLC/GVM-Docker/issues/new/choose). If you don't find a template that matches or simply want to ask a question, create a blank issue and add the appropriate labels.

* **Bug report**: Create a report to help us improve
* **Feature request**: Suggest an idea for this project

## How we use Git and GitHub

### Forking

We follow the [GitHub forking model](https://help.github.com/articles/fork-a-repo/) for collaborating on code. This model assumes that you have a remote called `upstream` which points to the official Detection Rules repo, which we'll refer to in later code snippets.


### Branching

This repository follows a similar approach to other repositories within the [Secure Compliance Solutions](https://github.com/Secure-Compliance-Solutions-LLC) organization, with a few exceptions that make our life easier. One way this repository is simpler is the lack of major version breaking changes. This means we have less backport commits to worry about and makes us a little more productive.

The basic branching workflow we follow for our code:

* All changes for the next release of code are made to the `main` branch
* During feature freeze for a release, we will create a branch from `main` for the release version `{majorVersion.minorVersion}`. This means that we can continue contributing to `main`, even during feature freeze, and it will just target `{majorVersion.minorVersion+1}`
* For bug fixes and other changes targeting the pending release during feature freeze, we will make those contributions to `{majorVersion.minorVersion}`. Periodically, we will then backport those changes from `{majorVersion.minorVersion}` to `main`



### What goes into a Pull Request

* Before you start on a PR you need to have a issue created first.
* Please include an explanation of your changes in your PR description.
* Links to relevant issues, external resources, or related PRs are very important and useful.
* Please try to explain *how* and *why* your rule works. Can you explain what makes the logic sound? Does it actually detect what it's supposed to? If you include the screenshot, please make sure to crop out any sensitive information!
* See [Submitting a Pull Request](#submitting-a-pull-request) for more info.


## Submitting a Pull Request

Push your local changes to your forked copy of the repository and submit a Pull Request. In the Pull Request, describe what your changes do and mention the number of the issue where discussion has taken place, e.g., "Closes #123".

Always submit your pull against `main` unless you are making changes for the pending release during feature freeze (see [Branching](#branching) for our branching strategy).

Then sit back and wait. We will probably have a discussion in the pull request and may request changes before merging. We're not trying to get in the way, but want to work with you to get your contributions in code.


### What to expect from a code review

After a pull is submitted, it needs to get to review. If you have commit permissions on the GVM-docker repo you will probably perform these steps while submitting your Pull Request. If not, a member of the SCS organization will do them for you, though you can help by suggesting a reviewer for your changes if you've interacted with someone while working on the issue.

Most likely, we will want to have a conversation in the pull request. We want to encourage contributions, but we also want to keep in mind how changes may affect other SCS users. 

### How we handle merges

We recognize that Git commit messages are a history of all changes to the repository. We want to make this history easy to read and as concise and clear as possible. When we merge a pull request, we squash commits using GitHub's "Squash and Merge" method of merging. This keeps a clear history to the repository, since we rarely need to know about the commits that happen *within* a working branch for a pull request.

The exception to this rule is backport PRs. We want to maintain that commit history, because the commits within a release branch have already been squashed. If we were to squash again to a single commit, we would just see a commit "Backport changes from `{majorVersion.minorVersion}`" show up in main. This would obscure the changes. For backport pull requests, we will either "Create a Merge Commit" or "Rebase and Merge." For more information, see [Branching](#branching) for our branching strategy.




