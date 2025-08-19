//SystemVerilog
module frame_assembler #(parameter DATA_W=8, HEADER=8'hAA) (
    input clk, rst, en,
    input [DATA_W-1:0] payload,
    output [DATA_W-1:0] frame_out,
    output frame_valid
);

wire [1:0] state;
wire [DATA_W-1:0] header_out;
wire [DATA_W-1:0] payload_out;
wire header_valid;
wire payload_valid;

// State machine controller
frame_state_controller #(
    .DATA_W(DATA_W)
) state_ctrl (
    .clk(clk),
    .rst(rst),
    .en(en),
    .state(state)
);

// Header generator
header_generator #(
    .DATA_W(DATA_W),
    .HEADER(HEADER)
) header_gen (
    .clk(clk),
    .rst(rst),
    .state(state),
    .header_out(header_out),
    .header_valid(header_valid)
);

// Payload handler
payload_handler #(
    .DATA_W(DATA_W)
) payload_hdl (
    .clk(clk),
    .rst(rst),
    .state(state),
    .payload(payload),
    .payload_out(payload_out),
    .payload_valid(payload_valid)
);

// Output multiplexer
assign frame_out = (state == 2'b01) ? header_out : 
                  (state == 2'b10) ? payload_out : 
                  0;
assign frame_valid = (state == 2'b01) ? header_valid :
                    (state == 2'b10) ? payload_valid :
                    0;

endmodule

module frame_state_controller #(parameter DATA_W=8) (
    input clk, rst, en,
    output reg [1:0] state
);

wire [1:0] next_state;
assign next_state = (state == 2'b00 && en) ? 2'b01 :
                   (state == 2'b01) ? 2'b10 :
                   (state == 2'b10) ? 2'b00 :
                   2'b00;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= 0;
    end else begin
        state <= next_state;
    end
end

endmodule

module header_generator #(parameter DATA_W=8, HEADER=8'hAA) (
    input clk, rst,
    input [1:0] state,
    output reg [DATA_W-1:0] header_out,
    output reg header_valid
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        header_out <= 0;
        header_valid <= 0;
    end else begin
        header_out <= HEADER;
        header_valid <= (state == 2'b01);
    end
end

endmodule

module payload_handler #(parameter DATA_W=8) (
    input clk, rst,
    input [1:0] state,
    input [DATA_W-1:0] payload,
    output reg [DATA_W-1:0] payload_out,
    output reg payload_valid
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        payload_out <= 0;
        payload_valid <= 0;
    end else begin
        payload_out <= payload;
        payload_valid <= (state == 2'b10);
    end
end

endmodule