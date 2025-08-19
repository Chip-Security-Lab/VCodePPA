//SystemVerilog
module shift_bidir_sync #(parameter WIDTH=16) (
    input clk,
    input rst,
    input dir,  // 0:left, 1:right
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

localparam SUB_WIDTH = 8;

wire [SUB_WIDTH-1:0] one_complement;
wire [SUB_WIDTH-1:0] din_sub;
wire [SUB_WIDTH-1:0] sub_result;
reg [WIDTH-1:0] shift_input;
reg [WIDTH-1:0] shift_result;

// Move register forward: register shift_input after combinational logic
assign one_complement = ~din[SUB_WIDTH-1:0];
assign din_sub = (dir == 1'b1) ? din[SUB_WIDTH-1:0] : {SUB_WIDTH{1'b0}};
assign sub_result = din_sub + one_complement + 1'b1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_input <= {WIDTH{1'b0}};
    end else begin
        if (dir) begin
            shift_input <= { {WIDTH-SUB_WIDTH{1'b0}}, sub_result };
        end else begin
            shift_input <= { {WIDTH-SUB_WIDTH{1'b0}}, din[SUB_WIDTH-1:0] };
        end
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_result <= {WIDTH{1'b0}};
        dout <= {WIDTH{1'b0}};
    end else begin
        if (dir) begin
            shift_result <= shift_input >> 1;
            dout <= { {WIDTH-SUB_WIDTH{1'b0}}, shift_result[SUB_WIDTH-1:0] };
        end else begin
            shift_result <= shift_input << 1;
            dout <= { {WIDTH-SUB_WIDTH{1'b0}}, shift_result[SUB_WIDTH-1:0] };
        end
    end
end

endmodule