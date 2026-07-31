import { on } from '@ember/modifier';
import type RouterService from '@ember/routing/router-service';
import { service } from '@ember/service';
import Component from '@glimmer/component';

import type { PaginationContentFeatures } from '@warp-drive/core/reactive';
import { EachLink } from '@warp-drive/ember';
import type { PaginationState, RealPaginationLink, RelationalPaginationLink } from '@warp-drive/ember';

import type { ReactiveTodosDocument } from '@workspace/shared-data/builders';

import { Button } from '#/components/design-system/button';
import { LoadingSpinner } from '#/components/design-system/loading';

interface Signature {
  Args: {
    pages: PaginationState<ReactiveTodosDocument>;
    state: PaginationContentFeatures<ReactiveTodosDocument>;
  };
}

export class PaginationControls extends Component<Signature> {
  <template>
    {{#if (or @pages.hasPrevious @pages.hasNext)}}
      <div class="pagination-controls">
        <div class="pagination-link-buttons">
          <EachLink @pages={{@pages}}>

            <:prev as |link|><NavButton @link={{link}} @page={{prevPage @pages}} /></:prev>

            <:link as |link|>
              {{#if (nearActive link)}}<PageButton @link={{link}} />{{/if}}
            </:link>

            <:placeholder>
              <span class="pagination-button pagination-placeholder-button">⋯</span>
            </:placeholder>

            <:next as |link|><NavButton @link={{link}} @page={{nextPage @pages}} /></:next>

          </EachLink>
        </div>

        {{#if this.isLoading}}<LoadingSpinner />{{/if}}
      </div>
    {{/if}}
  </template>

  // TODO @runspired work-around for no "page that isn't the prev or next page is loading" state
  get isLoading() {
    return [...this.args.pages.pages].some((p) => p.isLoading);
  }
}

/** A numbered page link (`:link` block). */
class PageButton extends Component<{
  Args: {
    link: RealPaginationLink;
  };
}> {
  <template>
    <Button
      {{on "click" this.setActive}}
      class="pagination-button pagination-real-button {{if @link.isCurrent 'pagination-button-active'}}"
    >
      <span class="pagination-button-text">{{@link.index}}</span>
    </Button>
  </template>

  @service declare router: RouterService;

  setActive = async () => {
    const { link } = this.args;
    this.router.transitionTo({ queryParams: { page: link.index } });
    await link.setActive();
  };
}

/** A relational prev/next link (`:prev` / `:next` blocks). */
class NavButton extends Component<{
  Args: {
    link: RelationalPaginationLink;
    page: number | null;
  };
}> {
  <template>
    <Button {{on "click" this.setActive}} class="pagination-button {{@link.rel}}">
      {{#if this.isPrev}}←{{/if}}
      <span class="pagination-button-text">Load {{if this.isPrev "previous" "next"}}</span>
      {{#unless this.isPrev}}→{{/unless}}
    </Button>
  </template>

  @service declare router: RouterService;

  get isPrev(): boolean {
    return this.args.link.rel === 'prev';
  }

  setActive = async () => {
    const { link, page } = this.args;
    this.router.transitionTo({ queryParams: { page } });
    await link.setActive();
  };
}

function prevPage(pages: PaginationState<ReactiveTodosDocument>): number | null {
  const n = pages.activePage?.pageNumber;
  return n ? n - 1 : null;
}

function nextPage(pages: PaginationState<ReactiveTodosDocument>): number | null {
  const n = pages.activePage?.pageNumber;
  return n ? n + 1 : null;
}

function or(a: unknown, b: unknown) {
  return a || b;
}

/** Only render numbered links within this many pages of the active page. */
const SHOW_DISTANCE = 3;

function nearActive(link: RealPaginationLink): boolean {
  return link.distanceFromActiveIndex <= SHOW_DISTANCE;
}
