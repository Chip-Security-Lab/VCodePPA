//SystemVerilog
module byte_enable_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter NUM_BYTES = DATA_WIDTH/8,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    we,
    input  wire [NUM_BYTES-1:0]    byte_en,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire [DATA_WIDTH-1:0]   rdata
);

    // Memory array with registered output
    reg [DATA_WIDTH-1:0] reg_array [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] rdata_reg;
    
    // Write control logic
    wire [DATA_WIDTH-1:0] write_mask;
    wire [DATA_WIDTH-1:0] write_data;
    
    // Generate write mask based on byte enables
    genvar i;
    generate
        for (i = 0; i < NUM_BYTES; i = i + 1) begin : gen_write_mask
            assign write_mask[i*8 +: 8] = {8{byte_en[i]}};
        end
    endgenerate
    
    // Brent-Kung adder implementation
    wire [DATA_WIDTH:0] carry;
    wire [DATA_WIDTH-1:0] p, g;
    wire [DATA_WIDTH-1:0] sum;
    
    // Generate propagate and generate signals
    genvar j;
    generate
        for (j = 0; j < DATA_WIDTH; j = j + 1) begin : gen_pg
            assign p[j] = reg_array[addr][j] ^ wdata[j];
            assign g[j] = reg_array[addr][j] & wdata[j];
        end
    endgenerate
    
    // Brent-Kung prefix computation
    wire [DATA_WIDTH-1:0] p_level1, g_level1;
    wire [DATA_WIDTH-1:0] p_level2, g_level2;
    wire [DATA_WIDTH-1:0] p_level3, g_level3;
    wire [DATA_WIDTH-1:0] p_level4, g_level4;
    wire [DATA_WIDTH-1:0] p_level5, g_level5;
    
    // Level 1
    assign p_level1[0] = p[0];
    assign g_level1[0] = g[0];
    generate
        for (j = 1; j < DATA_WIDTH; j = j + 1) begin : level1
            assign p_level1[j] = p[j] & p[j-1];
            assign g_level1[j] = g[j] | (p[j] & g[j-1]);
        end
    endgenerate
    
    // Level 2
    assign p_level2[0] = p_level1[0];
    assign g_level2[0] = g_level1[0];
    generate
        for (j = 1; j < DATA_WIDTH; j = j + 1) begin : level2
            assign p_level2[j] = p_level1[j] & p_level1[j-2];
            assign g_level2[j] = g_level1[j] | (p_level1[j] & g_level1[j-2]);
        end
    endgenerate
    
    // Level 3
    assign p_level3[0] = p_level2[0];
    assign g_level3[0] = g_level2[0];
    generate
        for (j = 1; j < DATA_WIDTH; j = j + 1) begin : level3
            assign p_level3[j] = p_level2[j] & p_level2[j-4];
            assign g_level3[j] = g_level2[j] | (p_level2[j] & g_level2[j-4]);
        end
    endgenerate
    
    // Level 4
    assign p_level4[0] = p_level3[0];
    assign g_level4[0] = g_level3[0];
    generate
        for (j = 1; j < DATA_WIDTH; j = j + 1) begin : level4
            assign p_level4[j] = p_level3[j] & p_level3[j-8];
            assign g_level4[j] = g_level3[j] | (p_level3[j] & g_level3[j-8]);
        end
    endgenerate
    
    // Level 5
    assign p_level5[0] = p_level4[0];
    assign g_level5[0] = g_level4[0];
    generate
        for (j = 1; j < DATA_WIDTH; j = j + 1) begin : level5
            assign p_level5[j] = p_level4[j] & p_level4[j-16];
            assign g_level5[j] = g_level4[j] | (p_level4[j] & g_level4[j-16]);
        end
    endgenerate
    
    // Final sum computation
    assign carry[0] = 1'b0;
    generate
        for (j = 0; j < DATA_WIDTH; j = j + 1) begin : final_sum
            assign carry[j+1] = g_level5[j];
            assign sum[j] = p[j] ^ carry[j];
        end
    endgenerate
    
    // Write data preparation with Brent-Kung adder
    assign write_data = sum & write_mask;
    
    // Write operation with registered output
    always @(posedge clk) begin
        if (reset) begin
            for (integer k = 0; k < DEPTH; k = k + 1) begin
                reg_array[k] <= {DATA_WIDTH{1'b0}};
            end
            rdata_reg <= {DATA_WIDTH{1'b0}};
        end 
        else begin
            if (we) begin
                reg_array[addr] <= (reg_array[addr] & ~write_mask) | write_data;
            end
            rdata_reg <= reg_array[addr];
        end
    end
    
    // Output assignment
    assign rdata = rdata_reg;
    
endmodule