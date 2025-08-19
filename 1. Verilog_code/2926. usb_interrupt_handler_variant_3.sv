//SystemVerilog
module usb_interrupt_handler #(
    parameter MAX_INT_ENDPOINTS = 8,
    parameter MAX_INTERVAL = 255
)(
    input wire clk,
    input wire rst_n,
    input wire [10:0] frame_number,
    input wire sof_received,
    input wire [MAX_INT_ENDPOINTS-1:0] endpoint_enabled,
    input wire [MAX_INT_ENDPOINTS-1:0] data_ready,
    input wire transfer_complete,
    input wire [3:0] completed_endpoint,
    output reg [3:0] endpoint_to_service,
    output reg transfer_request,
    output reg [1:0] handler_state
);
    localparam IDLE = 2'b00;
    localparam SCHEDULE = 2'b01;
    localparam WAIT = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // Interval configuration for each endpoint (in frames)
    reg [7:0] interval [0:MAX_INT_ENDPOINTS-1];
    
    // Last serviced frame for each endpoint
    reg [10:0] last_frame [0:MAX_INT_ENDPOINTS-1];
    
    // Pipeline registers for critical path cutting - increased pipeline depth
    reg [MAX_INT_ENDPOINTS-1:0] endpoint_enabled_stage1;
    reg [MAX_INT_ENDPOINTS-1:0] data_ready_stage1;
    reg [10:0] frame_number_stage1;
    reg [MAX_INT_ENDPOINTS-1:0] interval_qualified_stage1;
    reg [MAX_INT_ENDPOINTS-1:0] data_qualified_stage1;
    
    reg [MAX_INT_ENDPOINTS-1:0] endpoint_qualified_stage2;
    reg schedule_active_stage1;
    reg schedule_active_stage2;
    reg schedule_active_stage3;
    
    // Find first endpoint variables
    reg found_endpoint_stage2;
    reg found_endpoint_stage3;
    reg [3:0] priority_endpoint_stage2;
    reg [3:0] priority_endpoint_stage3;
    integer i;
    
    // Additional pipeline registers for state machine optimization
    reg transfer_request_internal;
    reg [1:0] handler_state_next;
    reg [MAX_INT_ENDPOINTS-1:0] endpoint_mask_stage3;
    
    // Initialize default intervals
    initial begin
        for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
            interval[i] = 8'd8;  // Default to 8ms interval
            last_frame[i] = 11'd0;
        end
        
        found_endpoint_stage2 = 1'b0;
        found_endpoint_stage3 = 1'b0;
        endpoint_to_service = 4'd0;
        transfer_request = 1'b0;
        handler_state = IDLE;
        schedule_active_stage1 = 1'b0;
        schedule_active_stage2 = 1'b0;
        schedule_active_stage3 = 1'b0;
        endpoint_qualified_stage2 = {MAX_INT_ENDPOINTS{1'b0}};
        interval_qualified_stage1 = {MAX_INT_ENDPOINTS{1'b0}};
        data_qualified_stage1 = {MAX_INT_ENDPOINTS{1'b0}};
        endpoint_enabled_stage1 = {MAX_INT_ENDPOINTS{1'b0}};
        data_ready_stage1 = {MAX_INT_ENDPOINTS{1'b0}};
        priority_endpoint_stage2 = 4'd0;
        priority_endpoint_stage3 = 4'd0;
        frame_number_stage1 = 11'd0;
        endpoint_mask_stage3 = {MAX_INT_ENDPOINTS{1'b0}};
    end
    
    // First pipeline stage - Input registration and split interval computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            endpoint_enabled_stage1 <= {MAX_INT_ENDPOINTS{1'b0}};
            data_ready_stage1 <= {MAX_INT_ENDPOINTS{1'b0}};
            frame_number_stage1 <= 11'd0;
            schedule_active_stage1 <= 1'b0;
        end else begin
            endpoint_enabled_stage1 <= endpoint_enabled;
            data_ready_stage1 <= data_ready;
            frame_number_stage1 <= frame_number;
            schedule_active_stage1 <= (handler_state == IDLE) && sof_received;
        end
    end
    
    // Signals for carry-skip adder
    wire [10:0] subtraction_result [0:MAX_INT_ENDPOINTS-1];
    wire [10:0] frame_diff [0:MAX_INT_ENDPOINTS-1];
    
    // Carry-skip adder implementation for frame difference calculation
    genvar g;
    generate
        for (g = 0; g < MAX_INT_ENDPOINTS; g = g + 1) begin: carry_skip_subtractors
            // Block size for carry-skip structure
            localparam BLOCK_SIZE = 4;
            
            // Propagate and generate signals
            wire [10:0] p; // Propagate
            wire [10:0] g_sig; // Generate
            wire [10:0] c; // Carry
            wire [2:0] block_p; // Block propagate
            
            // Calculate propagate and generate for each bit
            assign p[0] = frame_number_stage1[0] ^ ~last_frame[g][0];
            assign g_sig[0] = frame_number_stage1[0] & ~last_frame[g][0];
            assign c[0] = 1'b1; // Initial carry-in for subtraction
            
            // First block (bits 0-3)
            assign p[1] = frame_number_stage1[1] ^ ~last_frame[g][1];
            assign p[2] = frame_number_stage1[2] ^ ~last_frame[g][2];
            assign p[3] = frame_number_stage1[3] ^ ~last_frame[g][3];
            
            assign g_sig[1] = frame_number_stage1[1] & ~last_frame[g][1];
            assign g_sig[2] = frame_number_stage1[2] & ~last_frame[g][2];
            assign g_sig[3] = frame_number_stage1[3] & ~last_frame[g][3];
            
            // Block propagate for first block
            assign block_p[0] = p[0] & p[1] & p[2] & p[3];
            
            // Carry chain for first block
            assign c[1] = g_sig[0] | (p[0] & c[0]);
            assign c[2] = g_sig[1] | (p[1] & c[1]);
            assign c[3] = g_sig[2] | (p[2] & c[2]);
            
            // Second block (bits 4-7)
            assign p[4] = frame_number_stage1[4] ^ ~last_frame[g][4];
            assign p[5] = frame_number_stage1[5] ^ ~last_frame[g][5];
            assign p[6] = frame_number_stage1[6] ^ ~last_frame[g][6];
            assign p[7] = frame_number_stage1[7] ^ ~last_frame[g][7];
            
            assign g_sig[4] = frame_number_stage1[4] & ~last_frame[g][4];
            assign g_sig[5] = frame_number_stage1[5] & ~last_frame[g][5];
            assign g_sig[6] = frame_number_stage1[6] & ~last_frame[g][6];
            assign g_sig[7] = frame_number_stage1[7] & ~last_frame[g][7];
            
            // Block propagate for second block
            assign block_p[1] = p[4] & p[5] & p[6] & p[7];
            
            // Check if carry skips block 1
            wire skip_carry1 = block_p[0] ? c[0] : c[3];
            
            // Carry chain for second block with skip
            assign c[4] = g_sig[3] | (p[3] & skip_carry1);
            assign c[5] = g_sig[4] | (p[4] & c[4]);
            assign c[6] = g_sig[5] | (p[5] & c[5]);
            assign c[7] = g_sig[6] | (p[6] & c[6]);
            
            // Third block (bits 8-10)
            assign p[8] = frame_number_stage1[8] ^ ~last_frame[g][8];
            assign p[9] = frame_number_stage1[9] ^ ~last_frame[g][9];
            assign p[10] = frame_number_stage1[10] ^ ~last_frame[g][10];
            
            assign g_sig[8] = frame_number_stage1[8] & ~last_frame[g][8];
            assign g_sig[9] = frame_number_stage1[9] & ~last_frame[g][9];
            assign g_sig[10] = frame_number_stage1[10] & ~last_frame[g][10];
            
            // Block propagate for third block
            assign block_p[2] = p[8] & p[9] & p[10];
            
            // Check if carry skips block 2
            wire skip_carry2 = block_p[1] ? skip_carry1 : c[7];
            
            // Carry chain for third block with skip
            assign c[8] = g_sig[7] | (p[7] & skip_carry2);
            assign c[9] = g_sig[8] | (p[8] & c[8]);
            assign c[10] = g_sig[9] | (p[9] & c[9]);
            
            // Final sum calculation
            assign subtraction_result[g][0] = p[0] ^ c[0];
            assign subtraction_result[g][1] = p[1] ^ c[1];
            assign subtraction_result[g][2] = p[2] ^ c[2];
            assign subtraction_result[g][3] = p[3] ^ c[3];
            assign subtraction_result[g][4] = p[4] ^ c[4];
            assign subtraction_result[g][5] = p[5] ^ c[5];
            assign subtraction_result[g][6] = p[6] ^ c[6];
            assign subtraction_result[g][7] = p[7] ^ c[7];
            assign subtraction_result[g][8] = p[8] ^ c[8];
            assign subtraction_result[g][9] = p[9] ^ c[9];
            assign subtraction_result[g][10] = p[10] ^ c[10];
            
            // Calculate the frame difference
            assign frame_diff[g] = subtraction_result[g];
        end
    endgenerate
    
    // Second pipeline stage - Qualification processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interval_qualified_stage1 <= {MAX_INT_ENDPOINTS{1'b0}};
            data_qualified_stage1 <= {MAX_INT_ENDPOINTS{1'b0}};
            schedule_active_stage2 <= 1'b0;
        end else begin
            schedule_active_stage2 <= schedule_active_stage1;
            
            for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                // Use the carry-skip adder result for interval qualification
                interval_qualified_stage1[i] <= (frame_diff[i] >= {3'b000, interval[i]});
                data_qualified_stage1[i] <= endpoint_enabled_stage1[i] && data_ready_stage1[i];
            end
        end
    end
    
    // Third pipeline stage - Final qualification
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            endpoint_qualified_stage2 <= {MAX_INT_ENDPOINTS{1'b0}};
            schedule_active_stage3 <= 1'b0;
        end else begin
            schedule_active_stage3 <= schedule_active_stage2;
            
            for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                endpoint_qualified_stage2[i] <= interval_qualified_stage1[i] && data_qualified_stage1[i];
            end
        end
    end
    
    // Fourth pipeline stage - Priority encoder first part (endpoint detection)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            found_endpoint_stage2 <= 1'b0;
        end else begin
            found_endpoint_stage2 <= |endpoint_qualified_stage2;
        end
    end
    
    // Fifth pipeline stage - Priority encoder computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_endpoint_stage2 <= 4'd0;
            endpoint_mask_stage3 <= {MAX_INT_ENDPOINTS{1'b0}};
        end else begin
            casez(endpoint_qualified_stage2)
                8'b1???????: begin 
                    priority_endpoint_stage2 <= 4'd0;
                    endpoint_mask_stage3 <= 8'b10000000;
                end
                8'b01??????: begin
                    priority_endpoint_stage2 <= 4'd1;
                    endpoint_mask_stage3 <= 8'b01000000;
                end
                8'b001?????: begin
                    priority_endpoint_stage2 <= 4'd2;
                    endpoint_mask_stage3 <= 8'b00100000;
                end
                8'b0001????: begin
                    priority_endpoint_stage2 <= 4'd3;
                    endpoint_mask_stage3 <= 8'b00010000;
                end
                8'b00001???: begin
                    priority_endpoint_stage2 <= 4'd4;
                    endpoint_mask_stage3 <= 8'b00001000;
                end
                8'b000001??: begin
                    priority_endpoint_stage2 <= 4'd5;
                    endpoint_mask_stage3 <= 8'b00000100;
                end
                8'b0000001?: begin
                    priority_endpoint_stage2 <= 4'd6;
                    endpoint_mask_stage3 <= 8'b00000010;
                end
                8'b00000001: begin
                    priority_endpoint_stage2 <= 4'd7;
                    endpoint_mask_stage3 <= 8'b00000001;
                end
                default: begin
                    priority_endpoint_stage2 <= 4'd0;
                    endpoint_mask_stage3 <= 8'b00000000;
                end
            endcase
        end
    end
    
    // Sixth pipeline stage - Endpoint selection and state preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            found_endpoint_stage3 <= 1'b0;
            priority_endpoint_stage3 <= 4'd0;
        end else begin
            found_endpoint_stage3 <= found_endpoint_stage2;
            priority_endpoint_stage3 <= priority_endpoint_stage2;
        end
    end
    
    // Main state machine with separated state transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            handler_state_next <= IDLE;
            transfer_request_internal <= 1'b0;
        end else begin
            case(handler_state)
                IDLE: begin
                    transfer_request_internal <= 1'b0;
                    
                    if (schedule_active_stage3)
                        handler_state_next <= SCHEDULE;
                    else
                        handler_state_next <= IDLE;
                end
                
                SCHEDULE: begin
                    transfer_request_internal <= found_endpoint_stage3;
                    
                    if (found_endpoint_stage3)
                        handler_state_next <= WAIT;
                    else
                        handler_state_next <= IDLE;
                end
                
                WAIT: begin
                    if (transfer_complete && completed_endpoint == endpoint_to_service) begin
                        transfer_request_internal <= 1'b0;
                        handler_state_next <= COMPLETE;
                    end else begin
                        handler_state_next <= WAIT;
                    end
                end
                
                COMPLETE: begin
                    handler_state_next <= IDLE;
                end
                
                default: handler_state_next <= IDLE;
            endcase
        end
    end
    
    // Final output registers and frame update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            handler_state <= IDLE;
            endpoint_to_service <= 4'd0;
            transfer_request <= 1'b0;
            
            for (i = 0; i < MAX_INT_ENDPOINTS; i = i + 1) begin
                last_frame[i] <= 11'd0;
            end
        end else begin
            handler_state <= handler_state_next;
            transfer_request <= transfer_request_internal;
            
            if (handler_state == SCHEDULE && found_endpoint_stage3) begin
                endpoint_to_service <= priority_endpoint_stage3;
            end
            
            if (handler_state == WAIT && transfer_complete && 
                completed_endpoint == endpoint_to_service) begin
                last_frame[endpoint_to_service] <= frame_number;
            end
        end
    end
endmodule