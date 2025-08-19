//SystemVerilog
module shift_preload_pipelined #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input                   load,
    input  [WIDTH-1:0]      load_data,
    input                   in_valid,
    output                  out_valid,
    output [WIDTH-1:0]      sr
);

// Stage 1: Register inputs and input valid
reg [WIDTH-1:0] load_data_reg;
reg             load_reg;
reg             in_valid_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        load_data_reg <= {WIDTH{1'b0}};
        load_reg      <= 1'b0;
        in_valid_reg  <= 1'b0;
    end else begin
        load_data_reg <= load_data;
        load_reg      <= load;
        in_valid_reg  <= in_valid;
    end
end

// Stage 2: Register shift register and valid
reg [WIDTH-1:0] shift_reg;
reg             valid_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg  <= {WIDTH{1'b0}};
        valid_reg  <= 1'b0;
    end else if (in_valid_reg) begin
        if (load_reg)
            shift_reg <= load_data_reg;
        else
            shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
        valid_reg <= 1'b1;
    end else begin
        valid_reg <= 1'b0;
    end
end

assign sr        = shift_reg;
assign out_valid = valid_reg;

endmodule