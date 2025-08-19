module des_key_scheduler #(parameter KEY_WIDTH = 56, KEY_OUT = 48) (
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [5:0] round,
    output wire [KEY_OUT-1:0] subkey
);
    wire [KEY_WIDTH-1:0] rotated_key;
    // Left circular shift based on round number (PC-1 simplified)
    assign rotated_key = (round[0]) ? {key_in[KEY_WIDTH-2:0], key_in[KEY_WIDTH-1]} :
                                      {key_in[KEY_WIDTH-3:0], key_in[KEY_WIDTH-1:KEY_WIDTH-2]};
    // Compression permutation (PC-2 simplified)
    assign subkey = {rotated_key[45:20], rotated_key[19:0], rotated_key[55:46]};
endmodule