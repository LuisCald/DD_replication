import pandas as pd 
import numpy as np 

# Import and merge
brake_data_places = pd.read_csv(r"/Users/lc/Dropbox/Germany_state/2_Data_processing/2_period_data/1_prewar/brake_data.csv")
brake_data = pd.read_csv(r"/Users/lc/Dropbox/Germany_state/1_Data/1_data_from_digitizations/Topographie_der_gewalt/base_data_frontend.csv", delimiter=";")
final_df = brake_data_places.merge(brake_data, on="geonameid", how="left")
map_df = pd.read_csv(r"/Users/lc/Dropbox/Germany_state/1_Data/3_generated_data/admin_units_1930_adjusted.csv")

test = final_df.merge(map_df, left_on="FID_1", right_on="FID", how="right")
cols_to_drop = ['NEAR_DIST_y', 'NEAR_FID_y', 'NEW_NEAR_DIST', 'OBJECTID_y', 'ORIG_FID',
'PERIMETE_1', 'Rb_1', 'STATUS_1', 'Shape_Area', 'Shape_Leng', 'Type_1',
'dist_berlin', 'dual_color', 'exposure_prussia', 'holder_id',
'inc_random', 'inc_reason', 'inc_year', 'lat', 'level1_h', 'level1_o',
'lon', 'long_name', 'nap_ind', 'num', 'old_west_ind', 'owner_id',
'prussia_ind', 'segment_identifier', 'segment_identifier_alt1',
'segment_identifier_alt2', 'short_name', 'supra_id', 'variants',
'west_ind', 'west_middle', 'OBJECTID_x', 'OID_1', 'geonameid', 'alternaten', 'latitude',
       'longitude', 'country_co', 'population', 'Name_Zusat',
       'Name_Pl', 'Name_RU', 'Name_LT', 'Name_BY', 'AREA_x',
       'PERIMETER_x', 'LAND_x', 'STATUS_x', 'ID_x', 'RB_x', 'TYPE_x',
       'NEAR_FID_x', 'NEAR_DIST_x','event_id', 'placeDetail', 'event_id_A',
       'event_id_B', 'text_id','index', 'roughGeoCorrectionLon', 'roughGeoCorrectionLat',
       'FID', 'FID_1_y', 'FID_2',       'NAME_1', 'year',
       'new_lon', 'new_lat', 'Unnamed: 0','AREA_y', 'PERIMETER_y', 'Final_Name', 'FID_1_x', 'NAME_x',
       'LAND_y', 'STATUS_y', 'ID_y', 'RB_y', 'TYPE_y', 'AREA_1', 'ID_1', 'LAND_1', 'Latitude', 'Longitude' ]
test.drop(columns=cols_to_drop, inplace=True)   



cols_to_drop = ['OBJECTID', 'OID_1', 'geonameid', 'alternaten', 'latitude', 'longitude',
       'country_co', 'population', 'Final_Name', 'Name_Zusat', 'Name_Pl',
       'Name_RU', 'Name_LT', 'Name_BY', 'FID_1', 'AREA', 'PERIMETER', 'LAND', 'ID', 'RB', 'NEAR_FID', 'NEAR_DIST',
       'event_id', 'placeDetail', 'event_id_A', 'event_id_B', 'text_id', 'index',
       'roughGeoCorrectionLon', 'roughGeoCorrectionLat', 'new_lon', 'new_lat']
final_df.drop(columns=cols_to_drop, inplace=True)   

test.dropna(subset=["date_year"], inplace=True)
test.to_excel(r"/Users/lc/Dropbox/Germany_state/2_Data_processing/2_period_data/1_prewar/cleaned_brake_data.xlsx")          
