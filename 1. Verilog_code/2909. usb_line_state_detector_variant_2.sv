//SystemVerilog
module usb_line_state_detector(
    input wire clk,
    input wire rst_n,
    
    // Input interface with Valid-Ready handshake
    input wire [1:0] usb_data_in,     // {dp, dm}
    input wire data_valid,            // Indicates input data is valid
    output wire data_ready,           // Indicates module is ready for input
    
    // Output interface with Valid-Ready handshake
    output reg [1:0] line_state,
    output reg j_state,
    output reg k_state,
    output reg se0_state,
    output reg se1_state,
    output reg reset_detected,
    output reg output_valid,          // Indicates output data is valid
    input wire output_ready           // Downstream module is ready to accept data
);
    localparam J_STATE = 2'b01, K_STATE = 2'b10, SE0 = 2'b00, SE1 = 2'b11;
    
    reg [7:0] reset_counter;
    reg [1:0] prev_state;
    reg [1:0] dp_dm_reg;
    reg processing_state;
    
    // Ready signal generation - we're ready when not processing or when output is accepted
    assign data_ready = !processing_state || (output_valid && output_ready);
    
    // Input data capture with handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_dm_reg <= J_STATE;
            processing_state <= 1'b0;
        end else if (data_valid && data_ready) begin
            dp_dm_reg <= usb_data_in;
            processing_state <= 1'b1;
        end else if (output_valid && output_ready) begin
            processing_state <= 1'b0;
        end
    end
    
    // Line state detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_state <= J_STATE;
            prev_state <= J_STATE;
            output_valid <= 1'b0;
        end else if (processing_state && !output_valid) begin
            line_state <= dp_dm_reg;
            prev_state <= line_state;
            output_valid <= 1'b1;
        end else if (output_valid && output_ready) begin
            output_valid <= 1'b0;
        end
    end
    
    // State decoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            j_state <= 1'b0;
            k_state <= 1'b0;
            se0_state <= 1'b0;
            se1_state <= 1'b0;
        end else if (processing_state && !output_valid) begin
            j_state <= (dp_dm_reg == J_STATE);
            k_state <= (dp_dm_reg == K_STATE);
            se0_state <= (dp_dm_reg == SE0);
            se1_state <= (dp_dm_reg == SE1);
        end
    end
    
    // Reset counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_counter <= 8'd0;
        end else if (dp_dm_reg == SE0 && processing_state) begin
            if (reset_counter < 8'd255)
                reset_counter <= reset_counter + 8'd1;
        end else if (dp_dm_reg != SE0) begin
            reset_counter <= 8'd0;
        end
    end
    
    // Reset detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_detected <= 1'b0;
        end else if (dp_dm_reg == SE0 && processing_state) begin
            if (reset_counter > 8'd120) // ~2.5us @ 48MHz
                reset_detected <= 1'b1;
        end else if (dp_dm_reg != SE0) begin
            reset_detected <= 1'b0;
        end
    end
endmodule