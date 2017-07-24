pragma solidity ^0.4.11;

import "zeppelin/contracts/ownership/Ownable.sol";


// A Constitution is created when the DBVN is deployed
// The DBVN is the owner, but it can add editors (other DBVNs...)


contract Constitution is Ownable {
  mapping (address => bool) public editorIndex;

  // Some meta
  string public name;

  uint public numArticles;
  Article[] public allArticles;

  struct Article {
    string summary;
    string reference;

    address addedBy;

    bool isValid;

    uint createdAt;
    uint repealedAt;
  }

  event EditorAdded(address editor);
  event EditorRemoved(address editor);

  event ArticleAdded(uint articleId, address editor);
  event ArticleRepealed(uint articleId, address editor);

  modifier onlyEditor {
    require(isEditor(msg.sender));
    _;
  }

  function Constitution() {
    addEditor(msg.sender); // Owner should be an editor
  }

  // Owner functions

  function addEditor(address editor) onlyOwner {
    require(!isEditor(editor));

    editorIndex[editor] = true;

    EditorAdded(editor);
  }

  function removeEditor(address editor) onlyOwner {
    require(isEditor(editor));

    editorIndex[editor] = false;

    EditorRemoved(editor);
  }

  // Editors functions

  function addArticle(string articleSummary, string articleReference) onlyEditor returns (uint articleId) {
    articleId = numArticles++;

    allArticles[articleId] = Article({summary: articleSummary, reference: articleReference, addedBy: msg.sender, isValid: true, createdAt: now, repealedAt: 0});

    ArticleAdded(articleId, msg.sender);
  }

  function repealArticle(uint articleId) onlyEditor {
    require(allArticles[articleId].isValid);

    allArticles[articleId].isValid = false;
    allArticles[articleId].repealedAt = now;

    ArticleRepealed(articleId, msg.sender);
  }

  // Some utils

  function isEditor(address editor) constant returns (bool isEditor) {
    isEditor = editorIndex[editor];
  }
}
