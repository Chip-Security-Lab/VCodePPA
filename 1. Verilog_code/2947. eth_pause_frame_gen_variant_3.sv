//SystemVerilog
module eth_pause_frame_gen (
    input wire clk,
    input wire reset,
    input wire generate_pause,
    input wire [15:0] pause_time,
    input wire [47:0] local_mac,
    output reg [7:0] tx_data,
    output reg tx_en,
    output reg frame_complete
);
    // Multicast MAC address for PAUSE frames
    localparam [47:0] PAUSE_ADDR = 48'h010000C28001;
    localparam [15:0] MAC_CONTROL = 16'h8808;
    localparam [15:0] PAUSE_OPCODE = 16'h0001;
    
    // Optimized state encoding - one-hot encoding for better timing
    localparam [9:0] IDLE      = 10'b0000000001;
    localparam [9:0] PREAMBLE  = 10'b0000000010;
    localparam [9:0] SFD       = 10'b0000000100;
    localparam [9:0] DST_ADDR  = 10'b0000001000;
    localparam [9:0] SRC_ADDR  = 10'b0000010000;
    localparam [9:0] LENGTH    = 10'b0000100000;
    localparam [9:0] OPCODE    = 10'b0001000000;
    localparam [9:0] PAUSE_PARAM = 10'b0010000000;
    localparam [9:0] PAD       = 10'b0100000000;
    localparam [9:0] FCS       = 10'b1000000000;
    
    reg [9:0] state, next_state;
    reg [3:0] counter, next_counter;
    reg [7:0] next_tx_data;
    reg next_tx_en;
    reg next_frame_complete;
    
    // Registered signals for better timing
    reg [47:0] pause_addr_reg;
    reg [47:0] local_mac_reg;
    reg [15:0] mac_control_reg;
    reg [15:0] pause_opcode_reg;
    reg [15:0] pause_time_reg;
    
    // Pipeline registers for critical path
    reg [3:0] counter_pipe;
    reg [7:0] byte_select_stage1;
    reg [9:0] state_pipe;
    
    // DST/SRC address selection pipeline registers
    reg [47:0] addr_select_reg;
    reg [7:0] addr_byte_stage1;
    
    // Sequential logic - state registers and output registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            counter <= 4'd0;
            tx_en <= 1'b0;
            tx_data <= 8'd0;
            frame_complete <= 1'b0;
            
            // Register constants and inputs for better timing
            pause_addr_reg <= PAUSE_ADDR;
            mac_control_reg <= MAC_CONTROL;
            pause_opcode_reg <= PAUSE_OPCODE;
            
            // Reset pipeline registers
            counter_pipe <= 4'd0;
            byte_select_stage1 <= 8'd0;
            state_pipe <= IDLE;
            addr_select_reg <= 48'd0;
            addr_byte_stage1 <= 8'd0;
        end else begin
            state <= next_state;
            counter <= next_counter;
            tx_data <= next_tx_data;
            tx_en <= next_tx_en;
            frame_complete <= next_frame_complete;
            
            // Pipeline registers updates
            counter_pipe <= counter;
            state_pipe <= state;
            
            // Register inputs to improve timing
            local_mac_reg <= local_mac;
            pause_time_reg <= pause_time;
            
            // Pipeline stage for address selection
            case (state)
                DST_ADDR: addr_select_reg <= pause_addr_reg;
                SRC_ADDR: addr_select_reg <= local_mac_reg;
                default:  addr_select_reg <= addr_select_reg;
            endcase
            
            // Stage 1 for address byte selection
            case (counter)
                4'd0: addr_byte_stage1 <= addr_select_reg[47:40];
                4'd1: addr_byte_stage1 <= addr_select_reg[39:32];
                4'd2: addr_byte_stage1 <= addr_select_reg[31:24];
                4'd3: addr_byte_stage1 <= addr_select_reg[23:16];
                4'd4: addr_byte_stage1 <= addr_select_reg[15:8];
                4'd5: addr_byte_stage1 <= addr_select_reg[7:0];
                default: addr_byte_stage1 <= addr_byte_stage1;
            endcase
            
            // Stage 1 for other byte selections
            case (state)
                LENGTH: byte_select_stage1 <= counter[0] ? mac_control_reg[7:0] : mac_control_reg[15:8];
                OPCODE: byte_select_stage1 <= counter[0] ? pause_opcode_reg[7:0] : pause_opcode_reg[15:8];
                PAUSE_PARAM: byte_select_stage1 <= counter[0] ? pause_time_reg[7:0] : pause_time_reg[15:8];
                default: byte_select_stage1 <= 8'd0;
            endcase
        end
    end
    
    // Combinational logic - next state and output calculation
    always @(*) begin
        // Default assignments to prevent latches
        next_state = state;
        next_counter = counter;
        next_tx_data = tx_data;
        next_tx_en = tx_en;
        next_frame_complete = frame_complete;
        
        case (state)
            IDLE: begin
                next_tx_data = 8'd0;
                if (generate_pause) begin
                    next_state = PREAMBLE;
                    next_counter = 4'd0;
                    next_tx_en = 1'b1;
                    next_frame_complete = 1'b0;
                end else begin
                    next_tx_en = 1'b0;
                end
            end
            
            PREAMBLE: begin
                next_tx_data = 8'h55;
                if (counter == 4'd6) begin
                    next_state = SFD;
                    next_counter = 4'd0;
                end else
                    next_counter = counter + 4'd1;
            end
            
            SFD: begin
                next_tx_data = 8'hD5;
                next_state = DST_ADDR;
                next_counter = 4'd0;
            end
            
            DST_ADDR: begin
                // Use pipelined address byte selection
                next_tx_data = addr_byte_stage1;
                
                if (counter == 4'd5) begin
                    next_state = SRC_ADDR;
                    next_counter = 4'd0;
                end else
                    next_counter = counter + 4'd1;
            end
            
            SRC_ADDR: begin
                // Use pipelined address byte selection
                next_tx_data = addr_byte_stage1;
                
                if (counter == 4'd5) begin
                    next_state = LENGTH;
                    next_counter = 4'd0;
                end else
                    next_counter = counter + 4'd1;
            end
            
            LENGTH: begin
                // Use pipelined byte selection
                next_tx_data = byte_select_stage1;
                
                if (counter[0]) begin
                    next_state = OPCODE;
                    next_counter = 4'd0;
                end else
                    next_counter = 4'd1;
            end
            
            OPCODE: begin
                // Use pipelined byte selection
                next_tx_data = byte_select_stage1;
                
                if (counter[0]) begin
                    next_state = PAUSE_PARAM;
                    next_counter = 4'd0;
                end else
                    next_counter = 4'd1;
            end
            
            PAUSE_PARAM: begin
                // Use pipelined byte selection
                next_tx_data = byte_select_stage1;
                
                if (counter[0]) begin
                    next_state = PAD;
                    next_counter = 4'd0;
                end else
                    next_counter = 4'd1;
            end
            
            PAD: begin
                next_tx_data = 8'h00;
                if (counter == 4'd9) begin
                    next_state = FCS;
                    next_counter = 4'd0;
                end else
                    next_counter = counter + 4'd1;
            end
            
            FCS: begin
                // Simplified FCS - in a real design this would be calculated
                next_tx_data = 8'hAA;
                if (counter == 4'd3) begin
                    next_state = IDLE;
                    next_frame_complete = 1'b1;
                    next_tx_en = 1'b0;
                end else
                    next_counter = counter + 4'd1;
            end
            
            default: begin
                next_state = IDLE;
                next_counter = 4'd0;
                next_tx_en = 1'b0;
                next_tx_data = 8'd0;
                next_frame_complete = 1'b0;
            end
        endcase
    end
endmodule