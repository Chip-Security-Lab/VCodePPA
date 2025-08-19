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
reg j_valid_stage1, k_valid_stage1;

// Pipeline stage 2 registers
reg [DW-1:0] j_mem_data_stage2, k_mem_data_stage2;
reg j_we_stage2, j_oe_stage2, k_we_stage2, k_oe_stage2;
reg j_valid_stage2, k_valid_stage2;

// Stage 1: Address and control signal registration
always @(posedge clk) begin
    if (rst) begin
        j_valid_stage1 <= 0;
        k_valid_stage1 <= 0;
    end else begin
        j_addr_stage1 <= j_addr;
        j_din_stage1 <= j_din;
        j_we_stage1 <= j_we;
        j_oe_stage1 <= j_oe;
        j_valid_stage1 <= 1;

        k_addr_stage1 <= k_addr;
        k_din_stage1 <= k_din;
        k_we_stage1 <= k_we;
        k_oe_stage1 <= k_oe;
        k_valid_stage2 <= 1;
    end
end

// Stage 2: Memory access and data registration
always @(posedge clk) begin
    if (rst) begin
        j_valid_stage2 <= 0;
        k_valid_stage2 <= 0;
        j_write_count <= 0;
        j_read_count <= 0;
        k_write_count <= 0;
        k_read_count <= 0;
    end else begin
        j_valid_stage2 <= j_valid_stage1;
        k_valid_stage2 <= k_valid_stage1;
        
        j_we_stage2 <= j_we_stage1;
        j_oe_stage2 <= j_oe_stage1;
        k_we_stage2 <= k_we_stage1;
        k_oe_stage2 <= k_oe_stage1;

        // Memory access for Port J
        if (j_valid_stage1) begin
            if (j_we_stage1) begin
                mem[j_addr_stage1] <= j_din_stage1;
                j_write_count <= j_write_count + 1;
            end
            j_mem_data_stage2 <= mem[j_addr_stage1];
        end

        // Memory access for Port K
        if (k_valid_stage1) begin
            if (k_we_stage1) begin
                mem[k_addr_stage1] <= k_din_stage1;
                k_write_count <= k_write_count + 1;
            end
            k_mem_data_stage2 <= mem[k_addr_stage1];
        end
    end
end

// Stage 3: Output generation and counter updates
always @(posedge clk) begin
    if (rst) begin
        j_dout <= 0;
        k_dout <= 0;
    end else begin
        // Port J output
        if (j_valid_stage2) begin
            if (j_we_stage2 && j_oe_stage2) begin
                j_dout <= j_mem_data_stage2;
                j_read_count <= j_read_count + 1;
            end else if (j_we_stage2) begin
                j_dout <= {DW{1'b0}};
            end else if (j_oe_stage2) begin
                j_dout <= j_mem_data_stage2;
                j_read_count <= j_read_count + 1;
            end else begin
                j_dout <= {DW{1'b0}};
            end
        end

        // Port K output
        if (k_valid_stage2) begin
            if (k_we_stage2 && k_oe_stage2) begin
                k_dout <= k_mem_data_stage2;
                k_read_count <= k_read_count + 1;
            end else if (k_we_stage2) begin
                k_dout <= {DW{1'b0}};
            end else if (k_oe_stage2) begin
                k_dout <= k_mem_data_stage2;
                k_read_count <= k_read_count + 1;
            end else begin
                k_dout <= {DW{1'b0}};
            end
        end
    end
end

endmodule