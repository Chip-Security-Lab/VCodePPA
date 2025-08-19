//SystemVerilog
module usb_packet_error_checker(
    input wire clk,
    input wire rst_n,
    
    // Input interface - Valid/Ready
    input wire [7:0] data_in,
    input wire data_valid,
    output reg data_ready,
    
    // Control signals
    input wire packet_end,
    input wire [15:0] received_crc,
    
    // Output interface - Valid/Ready
    output reg [2:0] error_status,     // {crc_error, timeout_error, bitstuff_error}
    output reg error_valid,
    input wire error_ready
);
    // Internal registers - Stage 1 (Data reception)
    reg [15:0] calculated_crc_stage1;
    reg [7:0] data_in_stage1;
    reg data_valid_stage1;
    reg packet_end_stage1;
    reg [15:0] received_crc_stage1;
    
    // Internal registers - Stage 2 (CRC calculation)
    reg [15:0] calculated_crc_stage2;
    reg [15:0] intermediate_crc_stage2;
    reg packet_end_stage2;
    reg [15:0] received_crc_stage2;
    
    // Internal registers - Stage 3 (CRC finalization)
    reg [15:0] calculated_crc_stage3;
    reg packet_end_stage3;
    reg [15:0] received_crc_stage3;
    
    // Internal registers - Stage 4 (Error detection)
    reg crc_error_stage4;
    reg timeout_error_stage4;
    reg bitstuff_error_stage4;
    reg error_pending_stage4;
    
    // Timeout tracking
    reg [7:0] timeout_counter;
    reg receiving;
    
    // Error state tracking
    reg crc_error;
    reg timeout_error;
    reg bitstuff_error;
    
    // Pipeline stage 1: Data reception and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 8'd0;
            data_valid_stage1 <= 1'b0;
            packet_end_stage1 <= 1'b0;
            received_crc_stage1 <= 16'd0;
            calculated_crc_stage1 <= 16'hFFFF;
        end else begin
            if (data_valid && data_ready) begin
                data_in_stage1 <= data_in;
                data_valid_stage1 <= 1'b1;
                calculated_crc_stage1 <= calculated_crc_stage3;
            end else begin
                data_valid_stage1 <= 1'b0;
            end
            
            packet_end_stage1 <= packet_end;
            received_crc_stage1 <= received_crc;
        end
    end
    
    // Pipeline stage 2: CRC calculation - first part
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intermediate_crc_stage2 <= 16'h0000;
            calculated_crc_stage2 <= 16'hFFFF;
            packet_end_stage2 <= 1'b0;
            received_crc_stage2 <= 16'd0;
        end else begin
            if (data_valid_stage1) begin
                // XOR with input data
                intermediate_crc_stage2 <= calculated_crc_stage1 ^ {8'h00, data_in_stage1};
            end else begin
                intermediate_crc_stage2 <= calculated_crc_stage1;
            end
            
            calculated_crc_stage2 <= calculated_crc_stage1;
            packet_end_stage2 <= packet_end_stage1;
            received_crc_stage2 <= received_crc_stage1;
        end
    end
    
    // Pipeline stage 3: CRC calculation - second part
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calculated_crc_stage3 <= 16'hFFFF;
            packet_end_stage3 <= 1'b0;
            received_crc_stage3 <= 16'd0;
        end else begin
            if (data_valid_stage1) begin
                // Apply CRC polynomial
                calculated_crc_stage3 <= {intermediate_crc_stage2[14:0], 1'b0} ^ 
                                         (intermediate_crc_stage2[15] ? 16'h8005 : 16'h0000);
            end else if (packet_end_stage2) begin
                calculated_crc_stage3 <= 16'hFFFF; // Reset CRC on packet end
            end else begin
                calculated_crc_stage3 <= intermediate_crc_stage2;
            end
            
            packet_end_stage3 <= packet_end_stage2;
            received_crc_stage3 <= received_crc_stage2;
        end
    end
    
    // Pipeline stage 4: Error detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error_stage4 <= 1'b0;
            timeout_error_stage4 <= 1'b0;
            bitstuff_error_stage4 <= 1'b0;
            error_pending_stage4 <= 1'b0;
        end else begin
            if (packet_end_stage3) begin
                crc_error_stage4 <= (calculated_crc_stage3 != received_crc_stage3);
                error_pending_stage4 <= 1'b1;
            end else if (error_valid && error_ready) begin
                crc_error_stage4 <= 1'b0;
                timeout_error_stage4 <= 1'b0;
                bitstuff_error_stage4 <= 1'b0;
                error_pending_stage4 <= 1'b0;
            end
            
            // Timeout handling moves to this stage
            if (timeout_error) begin
                timeout_error_stage4 <= 1'b1;
                error_pending_stage4 <= 1'b1;
            end
        end
    end
    
    // Timeout detection logic (non-pipelined for immediate response)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_counter <= 8'd0;
            receiving <= 1'b0;
            timeout_error <= 1'b0;
        end else begin
            if (data_valid && data_ready) begin
                timeout_counter <= 8'd0;
                receiving <= 1'b1;
            end else if (receiving && !packet_end) begin
                timeout_counter <= timeout_counter + 1'b1;
                if (timeout_counter >= 8'd200) begin
                    timeout_error <= 1'b1;
                    receiving <= 1'b0;
                end
            end
            
            if (packet_end || (error_valid && error_ready)) begin
                receiving <= 1'b0;
                timeout_error <= 1'b0;
            end
        end
    end
    
    // Output stage: Error status and handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_status <= 3'b000;
            error_valid <= 1'b0;
            data_ready <= 1'b1;
            crc_error <= 1'b0;
            bitstuff_error <= 1'b0;
        end else begin
            // Generate error output when needed
            if (error_pending_stage4 && !error_valid) begin
                error_status <= {crc_error_stage4, timeout_error_stage4, bitstuff_error_stage4};
                error_valid <= 1'b1;
            end else if (error_valid && error_ready) begin
                error_valid <= 1'b0;
            end
            
            // Update main error tracking registers
            crc_error <= crc_error_stage4;
            bitstuff_error <= bitstuff_error_stage4;
            
            // Control data_ready based on error handling
            data_ready <= !error_valid || error_ready;
        end
    end
endmodule