//SystemVerilog
module usb_split_handler(
    input wire clk,
    input wire reset,
    input wire [3:0] hub_addr,
    input wire [3:0] port_num,
    input wire [7:0] transaction_type,
    input wire start_split,
    input wire complete_split,
    output reg [15:0] split_token,
    output reg token_valid,
    output reg [1:0] state
);
    // State definitions
    localparam IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, COMPLETE = 2'b11;
    
    // Pipeline stage registers
    reg [1:0] state_stage1, state_stage2;
    reg [3:0] hub_addr_stage1, hub_addr_stage2;
    reg [3:0] port_num_stage1, port_num_stage2;
    reg [7:0] transaction_type_stage1, transaction_type_stage2;
    reg start_split_stage1, start_split_stage2;
    reg complete_split_stage1, complete_split_stage2;
    reg [7:0] command_byte_stage1, command_byte_stage2;
    reg [15:0] split_token_stage1, split_token_stage2;
    reg token_valid_stage1, token_valid_stage2;
    reg pipeline_valid_stage1, pipeline_valid_stage2;
    
    // Stage 1: Input registration and command calculation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            hub_addr_stage1 <= 4'h0;
            port_num_stage1 <= 4'h0;
            transaction_type_stage1 <= 8'h0;
            start_split_stage1 <= 1'b0;
            complete_split_stage1 <= 1'b0;
            command_byte_stage1 <= 8'h0;
            split_token_stage1 <= 16'h0;
            token_valid_stage1 <= 1'b0;
            pipeline_valid_stage1 <= 1'b0;
        end else begin
            // Register inputs
            hub_addr_stage1 <= hub_addr;
            port_num_stage1 <= port_num;
            transaction_type_stage1 <= transaction_type;
            start_split_stage1 <= start_split;
            complete_split_stage1 <= complete_split;
            state_stage1 <= state;
            
            // Process command calculation - always validate pipeline first
            pipeline_valid_stage1 <= 1'b1;
            
            // Optimized command calculation with priority encoding
            token_valid_stage1 <= 1'b0; // Default value
            
            // Combined state and request condition checking for better timing
            if ((state == IDLE && (start_split || complete_split)) || 
                (state == WAIT && complete_split)) begin
                
                // Generate command byte based on transaction and request type
                // Use a more direct encoding structure to minimize logic levels
                if (complete_split || (state == WAIT)) begin
                    command_byte_stage1 <= {transaction_type[1:0], 2'b10, port_num};
                end else begin
                    command_byte_stage1 <= {transaction_type[1:0], 2'b00, port_num};
                end
                
                token_valid_stage1 <= 1'b1;
            end
        end
    end
    
    // Stage 2: Token generation and state transition
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= IDLE;
            hub_addr_stage2 <= 4'h0;
            port_num_stage2 <= 4'h0;
            transaction_type_stage2 <= 8'h0;
            start_split_stage2 <= 1'b0;
            complete_split_stage2 <= 1'b0;
            command_byte_stage2 <= 8'h0;
            split_token_stage2 <= 16'h0;
            token_valid_stage2 <= 1'b0;
            pipeline_valid_stage2 <= 1'b0;
        end else begin
            // Register stage 1 outputs
            state_stage2 <= state_stage1;
            hub_addr_stage2 <= hub_addr_stage1;
            port_num_stage2 <= port_num_stage1;
            transaction_type_stage2 <= transaction_type_stage1;
            start_split_stage2 <= start_split_stage1;
            complete_split_stage2 <= complete_split_stage1;
            command_byte_stage2 <= command_byte_stage1;
            token_valid_stage2 <= token_valid_stage1;
            pipeline_valid_stage2 <= pipeline_valid_stage1;
            
            // Generate token - moved condition check for better timing
            if (token_valid_stage1) begin
                split_token_stage2 <= {hub_addr_stage1, command_byte_stage1, 4'b0000}; // CRC5 omitted
            end
        end
    end
    
    // Stage 3: Output generation with optimized state transition logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            split_token <= 16'h0000;
            token_valid <= 1'b0;
        end else begin
            // Simplified token valid logic
            token_valid <= token_valid_stage2 && pipeline_valid_stage2;
            split_token <= split_token_stage2;
            
            // Optimized state transition logic with priority encoding
            if (pipeline_valid_stage2) begin
                case (state_stage2)
                    IDLE: begin
                        // Priority given to start_split over complete_split
                        if (start_split_stage2)
                            state <= START;
                        else if (complete_split_stage2)
                            state <= COMPLETE;
                        // else state remains IDLE (implicit)
                    end
                    
                    START: 
                        state <= WAIT;
                    
                    WAIT: begin
                        if (complete_split_stage2)
                            state <= COMPLETE;
                        // else state remains WAIT (implicit)
                    end
                    
                    COMPLETE: 
                        state <= IDLE;
                    
                    default: 
                        state <= IDLE;
                endcase
            end
        end
    end
endmodule