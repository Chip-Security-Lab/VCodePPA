//SystemVerilog
module i2c_multi_slave #(
    parameter ADDR_COUNT = 4,
    parameter ADDR_WIDTH = 7
)(
    input wire clk,
    input wire rst_sync_n,
    inout wire sda,
    inout wire scl,
    output reg [7:0] data_out [0:ADDR_COUNT-1],
    input wire [7:0] addr_mask [0:ADDR_COUNT-1]
);

    // =============================================
    // Internal signals declaration - structured by function
    // =============================================
    
    // Data path stage 1: Input capture and shift register
    reg [7:0] shift_reg;
    reg [2:0] bit_counter;
    reg byte_complete;  // Indicates when a full byte has been received
    
    // Data path stage 2: Address decoding and validation
    reg [ADDR_WIDTH-1:0] recv_addr;
    reg recv_addr_valid;
    reg [ADDR_COUNT-1:0] addr_match_vector;  // One-hot encoding for matched addresses
    
    // Data path stage 3: Data processing pipeline
    reg [7:0] processed_data;  // Pipeline register for data processing
    reg data_valid_stage1;     // Pipeline validity flag
    reg [ADDR_COUNT-1:0] addr_valid_stage1;  // Pipeline address match flags
    
    // =============================================
    // Stage 1: Input Capture Logic - Bit Level Processing
    // =============================================
    
    // Bit counter and shift register management
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg <= 8'h00;
            bit_counter <= 3'b000;
            byte_complete <= 1'b0;
        end 
        else begin
            // Default value for pulse signal
            byte_complete <= 1'b0;
            
            if (scl) begin
                // Shift in data from SDA on SCL rising edge
                shift_reg <= {shift_reg[6:0], sda};
                
                // Increment bit counter with rollover
                if (bit_counter == 3'b111) begin
                    bit_counter <= 3'b000;
                    byte_complete <= 1'b1;  // Signal byte completion
                end
                else begin
                    bit_counter <= bit_counter + 3'b001;
                end
            end
        end
    end
    
    // =============================================
    // Stage 2: Address Decoding - Byte Level Processing
    // =============================================
    
    // Address capture and validation
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            recv_addr <= {ADDR_WIDTH{1'b0}};
            recv_addr_valid <= 1'b0;
            data_valid_stage1 <= 1'b0;
        end
        else begin
            // Default state for pulse signals
            recv_addr_valid <= 1'b0;
            data_valid_stage1 <= 1'b0;
            
            if (byte_complete) begin
                // Store the received byte as an address
                recv_addr <= shift_reg[ADDR_WIDTH-1:0];
                recv_addr_valid <= 1'b1;
                
                // Forward data validity to next stage
                data_valid_stage1 <= 1'b1;
            end
        end
    end
    
    // Address matching logic - parallel processing for all addresses
    integer j;
    
    // Generate address match vector - combinational part
    always @* begin
        for (j=0; j<ADDR_COUNT; j=j+1) begin
            addr_match_vector[j] = (recv_addr == addr_mask[j][ADDR_WIDTH-1:0]) | 
                                 ((recv_addr & addr_mask[j][ADDR_WIDTH-1:0]) == addr_mask[j][ADDR_WIDTH-1:0]);
        end
    end
    
    // Address validation pipeline register
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            addr_valid_stage1 <= {ADDR_COUNT{1'b0}};
        end
        else if (recv_addr_valid) begin
            addr_valid_stage1 <= addr_match_vector;
        end
    end
    
    // =============================================
    // Stage 3: Data Processing - Compute and Store
    // =============================================
    
    // Pre-compute data transformation (increment operation)
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            processed_data <= 8'h00;
        end
        else if (data_valid_stage1) begin
            // Data transformation logic - increment operation
            processed_data <= shift_reg + 8'h01;
        end
    end
    
    // Final data output stage - store to appropriate output registers
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            for (j=0; j<ADDR_COUNT; j=j+1)
                data_out[j] <= 8'h00;
        end
        else begin
            for (j=0; j<ADDR_COUNT; j=j+1) begin
                if (addr_valid_stage1[j] & data_valid_stage1) begin
                    data_out[j] <= processed_data;
                end
            end
        end
    end
    
    // Initialize all registers (not required for synthesis, but helps in simulation)
    initial begin
        shift_reg = 8'h00;
        bit_counter = 3'b000;
        byte_complete = 1'b0;
        recv_addr = {ADDR_WIDTH{1'b0}};
        recv_addr_valid = 1'b0;
        processed_data = 8'h00;
        data_valid_stage1 = 1'b0;
        
        for (j=0; j<ADDR_COUNT; j=j+1) begin
            addr_valid_stage1[j] = 1'b0;
            data_out[j] = 8'h00;
        end
    end

endmodule