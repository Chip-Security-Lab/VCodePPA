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

    // Memory banks with one-hot bank selection
    reg [DATA_WIDTH-1:0] banks [0:NUM_BANKS-1][0:BANK_SIZE-1];
    wire [NUM_BANKS-1:0] bank_select = (1'b1 << bank_sel);
    
    // Write operation with optimized bank selection
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (int i = 0; i < NUM_BANKS; i++) begin
                for (int j = 0; j < BANK_SIZE; j++) begin
                    banks[i][j] <= {DATA_WIDTH{1'b0}};
                end
            end
        end
        else if (write_enable) begin
            for (int i = 0; i < NUM_BANKS; i++) begin
                if (bank_select[i]) begin
                    banks[i][write_addr] <= write_data;
                end
            end
        end
    end

    // Read operation with optimized bank selection
    always @(posedge clock) begin
        for (int i = 0; i < NUM_BANKS; i++) begin
            if (bank_select[i]) begin
                read_data <= banks[i][read_addr];
            end
        end
    end

endmodule