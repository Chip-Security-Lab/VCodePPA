//SystemVerilog
module subtractor_lut_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] minuend,
    input wire [7:0] subtrahend,
    output reg [7:0] difference
);

// Pipeline registers
reg [7:0] minuend_reg;
reg [7:0] subtrahend_reg;
reg [7:0] lut_addr_reg;

// LUT memory with registered output
reg [7:0] lut [0:255];
reg [7:0] lut_output_reg;

// LUT initialization
initial begin
    integer i;
    for (i = 0; i < 256; i = i + 1) begin
        lut[i] = i;
    end
end

// Pipeline stage 1: Input registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        minuend_reg <= 8'd0;
        subtrahend_reg <= 8'd0;
    end else begin
        minuend_reg <= minuend;
        subtrahend_reg <= subtrahend;
    end
end

// Pipeline stage 2: LUT address calculation and registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lut_addr_reg <= 8'd0;
    end else begin
        lut_addr_reg <= minuend_reg - subtrahend_reg;
    end
end

// Pipeline stage 3: LUT access and output registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lut_output_reg <= 8'd0;
    end else begin
        lut_output_reg <= lut[lut_addr_reg];
    end
end

// Pipeline stage 4: Final output registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        difference <= 8'd0;
    end else begin
        difference <= lut_output_reg;
    end
end

endmodule