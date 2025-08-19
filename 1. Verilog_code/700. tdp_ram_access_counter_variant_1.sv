//SystemVerilog
module tdp_ram_access_counter #(
    parameter DW = 24,
    parameter AW = 6
)(
    input clk, rst,
    // Port J
    input [AW-1:0] j_addr,
    input [DW-1:0] j_din,
    output reg [DW-1:0] j_dout,
    input j_we, j_oe,
    // Port K
    input [AW-1:0] k_addr,
    input [DW-1:0] k_din,
    output reg [DW-1:0] k_dout,
    input k_we, k_oe,
    // Debug interface
    output reg [31:0] j_write_count,
    output reg [31:0] j_read_count,
    output reg [31:0] k_write_count,
    output reg [31:0] k_read_count
);

(* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];

// Pipeline stage 1 registers
reg [AW-1:0] j_addr_stage1, k_addr_stage1;
reg [DW-1:0] j_din_stage1, k_din_stage1;
reg j_we_stage1, j_oe_stage1, k_we_stage1, k_oe_stage1;

// Pipeline stage 2 registers
reg [AW-1:0] j_addr_stage2, k_addr_stage2;
reg [DW-1:0] j_din_stage2, k_din_stage2;
reg j_we_stage2, j_oe_stage2, k_we_stage2, k_oe_stage2;
reg [DW-1:0] j_mem_data_stage2, k_mem_data_stage2;

// Stage 1: Input sampling with optimized reset
always @(posedge clk) begin
    if (rst) begin
        {j_addr_stage1, k_addr_stage1, j_din_stage1, k_din_stage1} <= 0;
        {j_we_stage1, j_oe_stage1, k_we_stage1, k_oe_stage1} <= 0;
    end else begin
        {j_addr_stage1, k_addr_stage1} <= {j_addr, k_addr};
        {j_din_stage1, k_din_stage1} <= {j_din, k_din};
        {j_we_stage1, j_oe_stage1, k_we_stage1, k_oe_stage1} <= {j_we, j_oe, k_we, k_oe};
    end
end

// Stage 2: Memory access and counter update with optimized operations
always @(posedge clk) begin
    if (rst) begin
        {j_addr_stage2, k_addr_stage2, j_din_stage2, k_din_stage2} <= 0;
        {j_we_stage2, j_oe_stage2, k_we_stage2, k_oe_stage2} <= 0;
        {j_mem_data_stage2, k_mem_data_stage2} <= 0;
        {j_write_count, j_read_count, k_write_count, k_read_count} <= 0;
        {j_dout, k_dout} <= 0;
    end else begin
        // Update stage 2 registers
        {j_addr_stage2, k_addr_stage2} <= {j_addr_stage1, k_addr_stage1};
        {j_din_stage2, k_din_stage2} <= {j_din_stage1, k_din_stage1};
        {j_we_stage2, j_oe_stage2, k_we_stage2, k_oe_stage2} <= {j_we_stage1, j_oe_stage1, k_we_stage1, k_oe_stage1};

        // Memory write operations with parallel updates
        if (j_we_stage1) begin
            mem[j_addr_stage1] <= j_din_stage1;
            j_write_count <= j_write_count + 1'b1;
        end
        if (k_we_stage1) begin
            mem[k_addr_stage1] <= k_din_stage1;
            k_write_count <= k_write_count + 1'b1;
        end

        // Memory read operations with parallel updates
        {j_mem_data_stage2, k_mem_data_stage2} <= {mem[j_addr_stage1], mem[k_addr_stage1]};

        // Output data with optimized mux
        j_dout <= j_oe_stage2 ? j_mem_data_stage2 : {DW{1'b0}};
        k_dout <= k_oe_stage2 ? k_mem_data_stage2 : {DW{1'b0}};

        // Read counter updates with parallel increments
        if (j_oe_stage2) j_read_count <= j_read_count + 1'b1;
        if (k_oe_stage2) k_read_count <= k_read_count + 1'b1;
    end
end

endmodule