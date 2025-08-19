//SystemVerilog
module i2c_dual_addr_mode_slave(
    input wire clk, rst_n,
    input wire [6:0] addr_7bit,
    input wire [9:0] addr_10bit,
    input wire addr_mode, // 0=7bit, 1=10bit
    output reg [7:0] data_rx,
    output reg data_valid,
    inout wire sda, scl
);
    localparam [2:0] IDLE = 3'b000,
                      ADDR = 3'b001,
                      DATA = 3'b010,
                      ACK  = 3'b011,
                      ADDR_10BIT = 3'b100;
                      
    // 10-bit address first byte pattern (MSB 5 bits)
    localparam [4:0] ADDR_10BIT_PREFIX = 5'b11110;
    
    reg [2:0] state, next_state;
    reg [9:0] addr_buffer, next_addr_buffer;
    reg [7:0] data_buffer, next_data_buffer;
    reg [3:0] bit_count, next_bit_count;
    reg sda_out, next_sda_out;
    reg sda_oe, next_sda_oe;
    
    // Pre-computed address comparison signals to reduce critical path
    reg addr_7bit_match, addr_10bit_prefix_match;
    
    // Move combinational logic before registers (retiming)
    always @(*) begin
        // Default assignments
        next_state = state;
        next_addr_buffer = addr_buffer;
        next_data_buffer = data_buffer;
        next_bit_count = bit_count;
        next_sda_out = sda_out;
        next_sda_oe = sda_oe;
        
        // Pre-compute address comparisons
        addr_7bit_match = (addr_buffer[7:1] == addr_7bit);
        addr_10bit_prefix_match = (addr_buffer[7:3] == ADDR_10BIT_PREFIX);
        
        case (state)
            ADDR: begin
                if (bit_count == 4'd8) begin
                    if ((!addr_mode && addr_7bit_match) || 
                        (addr_mode && addr_10bit_prefix_match)) begin
                        next_state = addr_mode ? ADDR_10BIT : DATA;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            
            // Rest of state machine would be implemented here
        endcase
    end
    
    // Retimed sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_valid <= 1'b0;
            addr_buffer <= 10'h0;
            data_buffer <= 8'h0;
            bit_count <= 4'h0;
            sda_out <= 1'b0;
            sda_oe <= 1'b1;
        end else begin
            state <= next_state;
            addr_buffer <= next_addr_buffer;
            data_buffer <= next_data_buffer;
            bit_count <= next_bit_count;
            sda_out <= next_sda_out;
            sda_oe <= next_sda_oe;
        end
    end

    assign sda = sda_oe ? 1'bz : sda_out;
endmodule