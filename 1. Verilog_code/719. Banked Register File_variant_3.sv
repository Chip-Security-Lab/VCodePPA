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
    wire [DATA_WIDTH-1:0] bank_data;
    wire [DATA_WIDTH-1:0] sum_out;
    
    // Optimized Han-Carlson adder using parallel prefix computation
    wire [DATA_WIDTH-1:0] p, g;
    wire [DATA_WIDTH-1:0] carry;
    
    assign bank_data = banks[bank_sel][write_addr];
    
    // Parallel prefix computation
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : prefix_adder
            assign p[i] = write_data[i] ^ bank_data[i];
            assign g[i] = write_data[i] & bank_data[i];
            
            if (i == 0) begin
                assign carry[i] = g[i];
            end else if (i == 1) begin
                assign carry[i] = g[i] | (p[i] & g[i-1]);
            end else if (i == 2) begin
                assign carry[i] = g[i] | (p[i] & g[i-1]) | (p[i] & p[i-1] & g[i-2]);
            end else begin
                assign carry[i] = g[i] | (p[i] & carry[i-1]);
            end
            
            assign sum_out[i] = p[i] ^ (i == 0 ? 1'b0 : carry[i-1]);
        end
    endgenerate
    
    // Read operation with registered output
    always @(posedge clock) begin
        read_data <= banks[bank_sel][read_addr];
    end
    
    // Write operation with reset
    integer j, k;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (j = 0; j < NUM_BANKS; j = j + 1) begin
                for (k = 0; k < BANK_SIZE; k = k + 1) begin
                    banks[j][k] <= {DATA_WIDTH{1'b0}};
                end
            end
        end else if (write_enable) begin
            banks[bank_sel][write_addr] <= sum_out;
        end
    end
endmodule