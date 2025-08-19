//SystemVerilog
module decoder_crc #(
    parameter AW = 8,
    parameter DW = 8
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [AW-1:0] addr,
    input  wire [DW-1:0] data,
    output reg         select
);

// Pipeline registers
reg [AW-1:0] addr_reg;
reg [DW-1:0] data_reg;
reg [7:0]    diff_reg;
reg [7:0]    crc_reg;
reg          addr_match_reg;

// Stage 1: Input registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_reg <= {AW{1'b0}};
        data_reg <= {DW{1'b0}};
    end else begin
        addr_reg <= addr;
        data_reg <= data;
    end
end

// Stage 2: Difference calculation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        diff_reg <= 8'h00;
    end else begin
        diff_reg <= addr_reg ^ data_reg;
    end
end

// Stage 3: CRC calculation with optimized logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_reg <= 8'h00;
    end else begin
        // Optimized CRC calculation with reduced logic depth
        crc_reg <= diff_reg ^ {1'b0, diff_reg[7:1] & ~data_reg[6:0]};
    end
end

// Stage 4: Address matching
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_match_reg <= 1'b0;
    end else begin
        addr_match_reg <= (addr_reg[7:4] == 4'b1010);
    end
end

// Stage 5: Final selection logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select <= 1'b0;
    end else begin
        select <= addr_match_reg && (crc_reg == 8'h55);
    end
end

endmodule