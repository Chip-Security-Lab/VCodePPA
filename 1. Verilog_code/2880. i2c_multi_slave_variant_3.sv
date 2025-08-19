//SystemVerilog
module i2c_multi_slave #(
    parameter ADDR_COUNT = 4,
    parameter ADDR_WIDTH = 7
)(
    input clk,
    input rst_sync_n,
    inout sda,
    inout scl,
    output reg [7:0] data_out [0:ADDR_COUNT-1],
    input [7:0] addr_mask [0:ADDR_COUNT-1]
);
// Unique feature: Four address matching engines
reg [ADDR_WIDTH-1:0] recv_addr;
reg addr_valid [0:ADDR_COUNT-1];
reg [7:0] shift_reg;
reg data_valid;

// Initialize all registers
integer j;
initial begin
    recv_addr = 0;
    data_valid = 0;
    shift_reg = 0;
    j = 0;
    while (j < ADDR_COUNT) begin
        addr_valid[j] = 0;
        data_out[j] = 0;
        j = j + 1;
    end
end

// Generate address matching logic
genvar i;
generate
for (i=0; i<ADDR_COUNT; i=i+1) begin : addr_filter
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n)
            addr_valid[i] <= 0;
        else
            addr_valid[i] <= (recv_addr == addr_mask[i][6:0]) || 
                            ((recv_addr & addr_mask[i][6:0]) == addr_mask[i][6:0]);
    end
end
endgenerate

// Parallel data processing
always @(posedge clk or negedge rst_sync_n) begin
    if (!rst_sync_n) begin
        j = 0;
        while (j < ADDR_COUNT) begin
            data_out[j] <= 8'h00;
            j = j + 1;
        end
    end else begin
        j = 0;
        while (j < ADDR_COUNT) begin
            if (addr_valid[j] && data_valid) begin
                data_out[j] <= shift_reg;
            end
            j = j + 1;
        end
    end
end

// Simplified data reception logic
always @(posedge clk or negedge rst_sync_n) begin
    if (!rst_sync_n) begin
        shift_reg <= 8'h00;
        data_valid <= 1'b0;
    end else if (scl) begin
        // Shift in data from SDA
        shift_reg <= {shift_reg[6:0], sda};
        // Set data valid at end of byte
        // This is simplified - actual implementation would count bits
        data_valid <= (shift_reg[7:0] != 0);
    end
end
endmodule