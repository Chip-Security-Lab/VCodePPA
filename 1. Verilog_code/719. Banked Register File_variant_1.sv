//SystemVerilog
module banked_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6,
    parameter NUM_BANKS = 4,
    parameter BANK_SIZE = 16,
    parameter TOTAL_SIZE = NUM_BANKS * BANK_SIZE
)(
    input  wire                          clock,
    input  wire                          resetn,
    input  wire [$clog2(NUM_BANKS)-1:0]  bank_sel,
    input  wire                          write_enable,
    input  wire [$clog2(BANK_SIZE)-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]         write_data,
    input  wire [$clog2(BANK_SIZE)-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]         read_data
);

    reg [DATA_WIDTH-1:0] banks [0:NUM_BANKS-1][0:BANK_SIZE-1];
    reg [DATA_WIDTH-1:0] read_data_reg;
    reg [DATA_WIDTH-1:0] write_data_reg;
    reg [$clog2(BANK_SIZE)-1:0] write_addr_reg;
    reg [$clog2(NUM_BANKS)-1:0] bank_sel_reg;
    reg write_enable_reg;
    integer i, j;

    // Parallel prefix adder implementation
    wire [DATA_WIDTH-1:0] write_data_pp;
    wire [DATA_WIDTH-1:0] bank_data_pp;
    wire [DATA_WIDTH-1:0] result_pp;

    // Generate propagate and generate signals
    wire [DATA_WIDTH-1:0] p, g;
    wire [DATA_WIDTH-1:0] p_level1, g_level1;
    wire [DATA_WIDTH-1:0] p_level2, g_level2;
    wire [DATA_WIDTH-1:0] p_level3, g_level3;
    wire [DATA_WIDTH-1:0] p_level4, g_level4;
    wire [DATA_WIDTH-1:0] p_level5, g_level5;
    wire [DATA_WIDTH-1:0] carry;

    // Compute propagate and generate signals
    assign p = write_data_reg ^ bank_data_pp;
    assign g = write_data_reg & bank_data_pp;

    // First level of prefix computation
    assign p_level1[0] = p[0];
    assign g_level1[0] = g[0];
    genvar k;
    generate
        for (k = 1; k < DATA_WIDTH; k = k + 1) begin
            assign p_level1[k] = p[k] & p[k-1];
            assign g_level1[k] = g[k] | (p[k] & g[k-1]);
        end
    endgenerate

    // Second level of prefix computation
    assign p_level2[0] = p_level1[0];
    assign g_level2[0] = g_level1[0];
    generate
        for (k = 1; k < DATA_WIDTH; k = k + 2) begin
            assign p_level2[k] = p_level1[k] & p_level1[k-1];
            assign g_level2[k] = g_level1[k] | (p_level1[k] & g_level1[k-1]);
        end
    endgenerate

    // Third level of prefix computation
    assign p_level3[0] = p_level2[0];
    assign g_level3[0] = g_level2[0];
    generate
        for (k = 1; k < DATA_WIDTH; k = k + 4) begin
            assign p_level3[k] = p_level2[k] & p_level2[k-2];
            assign g_level3[k] = g_level2[k] | (p_level2[k] & g_level2[k-2]);
        end
    endgenerate

    // Fourth level of prefix computation
    assign p_level4[0] = p_level3[0];
    assign g_level4[0] = g_level3[0];
    generate
        for (k = 1; k < DATA_WIDTH; k = k + 8) begin
            assign p_level4[k] = p_level3[k] & p_level3[k-4];
            assign g_level4[k] = g_level3[k] | (p_level3[k] & g_level3[k-4]);
        end
    endgenerate

    // Fifth level of prefix computation
    assign p_level5[0] = p_level4[0];
    assign g_level5[0] = g_level4[0];
    generate
        for (k = 1; k < DATA_WIDTH; k = k + 16) begin
            assign p_level5[k] = p_level4[k] & p_level4[k-8];
            assign g_level5[k] = g_level4[k] | (p_level4[k] & g_level4[k-8]);
        end
    endgenerate

    // Compute carry signals
    assign carry[0] = 1'b0;
    generate
        for (k = 1; k < DATA_WIDTH; k = k + 1) begin
            assign carry[k] = g_level5[k-1] | (p_level5[k-1] & carry[k-1]);
        end
    endgenerate

    // Compute final result
    assign result_pp = p ^ {carry[DATA_WIDTH-2:0], 1'b0};

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < NUM_BANKS; i = i + 1) begin
                for (j = 0; j < BANK_SIZE; j = j + 1) begin
                    banks[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
            read_data_reg <= {DATA_WIDTH{1'b0}};
            read_data <= {DATA_WIDTH{1'b0}};
            write_data_reg <= {DATA_WIDTH{1'b0}};
            write_addr_reg <= {($clog2(BANK_SIZE)){1'b0}};
            bank_sel_reg <= {($clog2(NUM_BANKS)){1'b0}};
            write_enable_reg <= 1'b0;
        end
        else begin
            write_data_reg <= write_data;
            write_addr_reg <= write_addr;
            bank_sel_reg <= bank_sel;
            write_enable_reg <= write_enable;
            
            read_data_reg <= banks[bank_sel][read_addr];
            read_data <= read_data_reg;
            
            if (write_enable_reg) begin
                banks[bank_sel_reg][write_addr_reg] <= result_pp;
            end
        end
    end

    assign bank_data_pp = banks[bank_sel_reg][write_addr_reg];
    assign write_data_pp = write_data_reg;

endmodule