pragma solidity ^0.4.13;

import "ds-test/test.sol";
import "./Constitution.sol";

// We only check the new functions, basic ones are already tested by zeppelin


contract User {
    Constitution constitution;

    function User(Constitution const) {
        constitution = const;
    }

    function addArticle(string summary, string reference) returns (uint) {
        return constitution.addArticle(summary, reference);
    }

    function repealArticle(uint id) {
        constitution.repealArticle(id);
    }
}

contract TestConstitutionn is DSTest {

    Constitution const;
    User user;

    // token will be instantiated before each test case
    function setUp() {
        const = new Constitution();
        user = new User(const);        
    }

    function test_ownerShouldBeAnEditor() {
        assert(const.isEditor(this));
    }

    function test_addEditor() {
        const.addEditor(user);

        assert(const.isEditor(user));
    }

    function test_removeEditor() {
        const.addEditor(user);
        const.removeEditor(user);

        assert(!const.isEditor(user));
    }

    function testFail_removeNonExistingditor() {
        const.removeEditor(user);
    }

    function test_editorCanAddManyArticles() {
        const.addEditor(user);

        assert(user.addArticle("t", "t") == 0);
        assert(user.addArticle("t", "t") == 1);
        assert(user.addArticle("t", "t") == 2);

        assert(const.numArticles() == 3);

        // Just test for one article, we use 2 so it checks
        // that the articles are not overflowed at the same time

        // `[dev::tag_comment*] = Encoding type "inaccessible dynamic type" not yet implemented.`

        var ( , , addedBy, isValid, createdAt, repealedAt) = const.allArticles(2);

        //assert(sha3(summary) == sha3("t"));
        //assert(sha3(reference) == sha3("t"));
        assert(addedBy == address(user));
        assert(isValid);
        assert(createdAt != 0);
        assert(repealedAt == 0);
    }

    function test_editorCanRepealArticle() {
        const.addEditor(user);

        assert(user.addArticle("t", "t") == 0);

        user.repealArticle(0);

        var ( , , , isValid, , ) = const.allArticles(0);
        assert(!isValid);
    }
}
