module twofish_key_schedule (
    input clk, key_update,
    input [255:0] master_key,
    output reg [31:0] round_key
);
    reg [255:0] me_key, mo_key;
    integer cnt;
    
    always @(posedge clk) begin
        if (key_update) begin
            me_key <= master_key[255:128];
            mo_key <= master_key[127:0];
            cnt <= 0;
        end else begin
            round_key <= (me_key[cnt*32+:32] + mo_key[cnt*32+:32]) <<< 9;
            cnt <= cnt + 1;
        end
    end
endmodule
