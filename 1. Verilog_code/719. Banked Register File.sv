module banked_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6,
    parameter NUM_BANKS = 4,
    parameter BANK_SIZE = 16,
    parameter TOTAL_SIZE = NUM_BANKS * BANK_SIZE
)(
    input  wire                          clock,
    input  wire                          resetn,
    
    // Bank select (which bank to operate on)
    input  wire [$clog2(NUM_BANKS)-1:0]  bank_sel,
    
    // Write port
    input  wire                          write_enable,
    input  wire [$clog2(BANK_SIZE)-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]         write_data,
    
    // Read port
    input  wire [$clog2(BANK_SIZE)-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]         read_data
);
    // Declare banks
    reg [DATA_WIDTH-1:0] banks [0:NUM_BANKS-1][0:BANK_SIZE-1];
    
    // Read operation (registered)
    always @(posedge clock) begin
        read_data <= banks[bank_sel][read_addr];
    end
    
    // Write operation
    integer i, j;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            // Reset all banks
            for (i = 0; i < NUM_BANKS; i = i + 1) begin
                for (j = 0; j < BANK_SIZE; j = j + 1) begin
                    banks[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
        end
        else if (write_enable) begin
            banks[bank_sel][write_addr] <= write_data;
        end
    end
endmodule