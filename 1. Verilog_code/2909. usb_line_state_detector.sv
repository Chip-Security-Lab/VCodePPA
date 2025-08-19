module usb_line_state_detector(
    input wire clk,
    input wire rst_n,
    input wire dp,
    input wire dm,
    output reg [1:0] line_state,
    output reg j_state,
    output reg k_state,
    output reg se0_state,
    output reg se1_state,
    output reg reset_detected
);
    localparam J_STATE = 2'b01, K_STATE = 2'b10, SE0 = 2'b00, SE1 = 2'b11;
    
    reg [7:0] reset_counter;
    reg [1:0] prev_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_state <= J_STATE;
            j_state <= 1'b0;
            k_state <= 1'b0;
            se0_state <= 1'b0;
            se1_state <= 1'b0;
            reset_counter <= 8'd0;
            reset_detected <= 1'b0;
            prev_state <= J_STATE;
        end else begin
            // Determine line state based on DP and DM
            line_state <= {dp, dm};
            prev_state <= line_state;
            
            // Decode line states
            j_state <= (line_state == J_STATE);
            k_state <= (line_state == K_STATE);
            se0_state <= (line_state == SE0);
            se1_state <= (line_state == SE1);
            
            // Reset detection (SE0 for >2.5us)
            if (line_state == SE0) begin
                if (reset_counter < 8'd255)
                    reset_counter <= reset_counter + 8'd1;
                if (reset_counter > 8'd120) // ~2.5us @ 48MHz
                    reset_detected <= 1'b1;
            end else begin
                reset_counter <= 8'd0;
                reset_detected <= 1'b0;
            end
        end
    end
endmodule