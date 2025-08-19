//SystemVerilog
module eth_preamble_detector (
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_dv,
    output reg preamble_detected,
    output reg sfd_detected
);
    // Constants
    localparam PREAMBLE_BYTE = 8'h55;
    localparam SFD_BYTE = 8'hD5;
    
    // Renamed and reorganized registers for better retiming
    reg [2:0] preamble_count;
    reg preamble_match, sfd_match;
    reg preamble_valid, sfd_valid;
    
    // Direct input comparisons - moved before registers
    wire data_is_preamble = (rx_data == PREAMBLE_BYTE) && rx_dv;
    wire data_is_sfd = (rx_data == SFD_BYTE) && rx_dv;
    
    // Counter logic - moved before validation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            preamble_count <= 3'd0;
        end else begin
            if (!rx_dv) begin
                preamble_count <= 3'd0;
            end else if (data_is_preamble) begin
                if (preamble_count < 7)
                    preamble_count <= preamble_count + 1'b1;
            end else if (!data_is_preamble && !data_is_sfd) begin
                preamble_count <= 3'd0;
            end
        end
    end
    
    // Match detection logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            preamble_match <= 1'b0;
            sfd_match <= 1'b0;
        end else begin
            preamble_match <= data_is_preamble;
            sfd_match <= data_is_sfd;
        end
    end
    
    // Validation logic with retimed criteria
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            preamble_valid <= 1'b0;
            sfd_valid <= 1'b0;
        end else begin
            preamble_valid <= preamble_match && (preamble_count >= 2);
            sfd_valid <= sfd_match && (preamble_count >= 6);
        end
    end
    
    // Output generation with retimed registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            preamble_detected <= 1'b0;
            sfd_detected <= 1'b0;
        end else begin
            if (!rx_dv) begin
                preamble_detected <= 1'b0;
                sfd_detected <= 1'b0;
            end else begin
                preamble_detected <= preamble_valid;
                
                if (sfd_valid) begin
                    sfd_detected <= 1'b1;
                end else if (!preamble_valid) begin
                    sfd_detected <= 1'b0;
                end
            end
        end
    end
endmodule