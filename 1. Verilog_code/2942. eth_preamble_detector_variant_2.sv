//SystemVerilog
module eth_preamble_detector (
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_dv,
    output reg preamble_detected,
    output reg sfd_detected
);
    localparam PREAMBLE_BYTE = 8'h55;
    localparam SFD_BYTE = 8'hD5;
    
    // Register input signals to reduce input to first register delay
    reg [7:0] rx_data_r;
    reg rx_dv_r;
    
    // Create additional pipeline stage for intermediate signals
    reg [2:0] preamble_count;
    reg [2:0] preamble_count_next;
    reg preamble_detected_next;
    reg sfd_detected_next;
    
    // Register input signals
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data_r <= 8'h0;
            rx_dv_r <= 1'b0;
        end else begin
            rx_data_r <= rx_data;
            rx_dv_r <= rx_dv;
        end
    end
    
    // Combinational logic for next state calculation
    always @(*) begin
        preamble_count_next = preamble_count;
        preamble_detected_next = 1'b0;
        sfd_detected_next = 1'b0;
        
        if (rx_dv_r) begin
            // Preamble counter logic
            if (rx_data_r == PREAMBLE_BYTE) begin
                if (preamble_count < 7)
                    preamble_count_next = preamble_count + 1'b1;
                
                // Preamble detection logic
                if (preamble_count >= 2)
                    preamble_detected_next = 1'b1;
            end else if (rx_data_r == SFD_BYTE && preamble_count >= 6) begin
                preamble_count_next = 3'd0;
                sfd_detected_next = 1'b1;
            end else begin
                preamble_count_next = 3'd0;
                if (rx_data_r == SFD_BYTE) begin
                    preamble_detected_next = preamble_detected;
                end
            end
        end
    end
    
    // Sequential logic - moved after combinational logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            preamble_count <= 3'd0;
            preamble_detected <= 1'b0;
            sfd_detected <= 1'b0;
        end else begin
            preamble_count <= preamble_count_next;
            preamble_detected <= preamble_detected_next;
            sfd_detected <= sfd_detected_next;
        end
    end
    
endmodule