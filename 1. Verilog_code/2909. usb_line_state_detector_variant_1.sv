//SystemVerilog
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
    // Constants definition
    localparam J_STATE = 2'b01, K_STATE = 2'b10, SE0 = 2'b00, SE1 = 2'b11;
    
    // Input and state capture registers
    reg dp_reg, dm_reg;
    reg [1:0] curr_line_state;
    reg [1:0] prev_line_state;
    
    // Direct state decode registers (moved backward from output)
    reg j_state_reg;
    reg k_state_reg;
    reg se0_state_reg;
    reg se1_state_reg;
    
    // Reset detection registers
    reg [7:0] se0_counter;
    reg reset_detected_reg;
    
    // Input capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_reg <= 1'b0;
            dm_reg <= 1'b0;
        end else begin
            dp_reg <= dp;
            dm_reg <= dm;
        end
    end
    
    // Current and previous state capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_line_state <= J_STATE;
            prev_line_state <= J_STATE;
        end else begin
            curr_line_state <= {dp_reg, dm_reg};
            prev_line_state <= curr_line_state;
        end
    end
    
    // Retimed direct state decoding (moved before the final output stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            j_state_reg <= 1'b0;
            k_state_reg <= 1'b0;
            se0_state_reg <= 1'b0;
            se1_state_reg <= 1'b0;
        end else begin
            j_state_reg <= (curr_line_state == J_STATE);
            k_state_reg <= (curr_line_state == K_STATE);
            se0_state_reg <= (curr_line_state == SE0);
            se1_state_reg <= (curr_line_state == SE1);
        end
    end
    
    // Simplified reset counter logic (moved logic from later stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            se0_counter <= 8'd0;
        end else begin
            if (curr_line_state == SE0) begin
                if (se0_counter < 8'd255)
                    se0_counter <= se0_counter + 8'd1;
            end else begin
                se0_counter <= 8'd0;
            end
        end
    end
    
    // Reset detection (moved backward from output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected_reg <= 1'b0;
        end else begin
            reset_detected_reg <= (se0_counter > 8'd120); // ~2.5us @ 48MHz
        end
    end
    
    // Final output registers (simplified as they now only sample the internal registers)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_state <= J_STATE;
            j_state <= 1'b0;
            k_state <= 1'b0;
            se0_state <= 1'b0;
            se1_state <= 1'b0;
            reset_detected <= 1'b0;
        end else begin
            line_state <= curr_line_state;
            j_state <= j_state_reg;
            k_state <= k_state_reg;
            se0_state <= se0_state_reg;
            se1_state <= se1_state_reg;
            reset_detected <= reset_detected_reg;
        end
    end
endmodule