from pydantic import BaseModel, Field
from typing import Literal, Annotated, Union, Optional, List
import json

PanelNumberT = Union[Annotated[int, Field(ge=1, le=21)], Literal['E-X045', 'E-X045', 'E-X135', 'E-X135', 'E-X225', 'E-X225', 'E-X315', 'E-X315']]
PaddleNumberT = Annotated[int, Field(ge=1, le=160)]
RatNumberT = Annotated[int, Field(ge=1, le=20)]
HartingT = Annotated[str, Field(length=2, pattern=r"J[1-5]")]  # "J2"
NumberChannelT = Annotated[str, Field(length=5, pattern=r"\d{2}-\d{2}")]
LtbChannelT = Annotated[str, Field(pattern=r"\d+-\d+")]  # "19-11" # "7-11"
PaddleLocationT = Union[Annotated[str, Field(pattern=r"[+-][0-9][XYZ]")],
                        Annotated[str, Field(pattern=r"[+-][0-1][XYZ],[+-][0-1][XYZ]")],
                        Annotated[int, Field(ge=0, le=0)]]
MtbLinkIdT = Annotated[int, Field(ge=0, le=49)]


class MapEntry (BaseModel):
    paddle_number: PaddleNumberT = Field(alias='Paddle Number')
    paddle_end: Literal['A', 'B'] = Field(alias='Paddle End (A/B)')
    paddle_end_location: Literal['+Y', '-Y', '+X', '-X', '+Z', '-Z'] = Field(alias="Paddle End Location")
    panel_number: PanelNumberT = Field(alias="Panel Number")
    panel_center: Optional[float] = Field(alias="Panel Center")
    paddle_location_in_panel: PaddleLocationT = Field(alias="Paddle Location in Panel ")
    cable_length: float = Field(alias="Cable length (cm)")
    rat_number: RatNumberT = Field(alias="RAT Number")
    ltb_number_channel: LtbChannelT = Field(alias="LTB Number-Channel")
    rb_number_channel: NumberChannelT = Field(alias="RB Number-Channel")
    dsi_card_slot: int = Field(alias="DSI Card Slot")
    ltb_harting_connection: HartingT = Field(alias="LTB Harting Connection")
    rb_harting_connection: HartingT = Field(alias="RB Harting Connection")
    pb_number_channel: NumberChannelT = Field(alias="PB Number-Channel")
    pb_controlled_by_which_rb: int = Field(alias="PB controlled by which RB")
    ltb_controlled_by_which_rb: int = Field(alias="LTB controlled by which RB")
    panel_type: Literal['umbrella', 'cortina', 'corner', 'cube top', 'cube bottom', 'cube side'] = Field(alias="Panel Type")
    rb_harting_connection_split: Literal['A', 'B'] = Field(alias="RB Harting connection split")
    mtb_link_id: MtbLinkIdT = Field(alias="MTB Link ID")
    paddle_length: Optional[float] = Field(alias="Paddle Length")
    paddle_width: Optional[float] = Field(alias="Paddle Width")

class GapsMap(BaseModel):
    mapping: List[MapEntry]


with open('mapping.json') as f:
    m = GapsMap(mapping=json.load(f))
    with open('mapping-sanitized.json', 'w+') as output:
        output.write(m.model_dump_json())
