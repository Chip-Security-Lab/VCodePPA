//SystemVerilog
module MuxParity #(parameter W=8) (
    input [3:0][W:0] data_ch, // [W] is parity
    input [1:0] sel,
    output reg [W:0] data_out
);

// Booth multiplier implementation
reg [W:0] booth_result;
reg [W:0] booth_accum;
reg [1:0] booth_state;
reg [1:0] booth_count;

// Bucket shift register implementation
wire [W:0] shifted_data[0:W-1];

generate
    genvar i;
    for (i = 0; i < W; i = i + 1) begin : shift_bucket
        assign shifted_data[i] = data_ch[sel] << i;
    end
endgenerate

always @(*) begin
    case(sel)
        2'b00: booth_result = data_ch[0];
        2'b01: booth_result = data_ch[1];
        2'b10: booth_result = data_ch[2];
        2'b11: booth_result = data_ch[3];
    endcase
    
    booth_accum = {W{1'b0}};
    booth_state = 2'b00;
    booth_count = 2'b00;
    
    for (integer i = 0; i < W; i = i + 1) begin
        case({booth_result[i], booth_state})
            3'b000: booth_accum = booth_accum;
            3'b001: booth_accum = booth_accum + shifted_data[i];
            3'b010: booth_accum = booth_accum - shifted_data[i];
            3'b011: booth_accum = booth_accum - shifted_data[i];
            3'b100: booth_accum = booth_accum + shifted_data[i];
            3'b101: booth_accum = booth_accum + shifted_data[i];
            3'b110: booth_accum = booth_accum;
            3'b111: booth_accum = booth_accum;
        endcase
        booth_state = {booth_result[i], booth_state[1]};
    end
    
    data_out = booth_accum;
    data_out[W] = ^data_out[W-1:0];
end

endmodule