//SystemVerilog
module EdgeDetector #(
    parameter PULSE_WIDTH = 2
)(
    input clk, rst_async,
    input signal_in,
    output reg rising_edge,
    output reg falling_edge
);
    // Stage 1: Input synchronization
    reg [1:0] sync_reg;
    reg edge_valid_stage1;
    reg [1:0] edge_type_stage1;

    // Stage 2: Edge detection pipeline registers
    reg edge_valid_stage2;
    reg [1:0] edge_type_stage2;
    reg [PULSE_WIDTH-1:0] pulse_counter [1:0];

    // Edge type definitions
    localparam RISING_EDGE = 2'b01;
    localparam FALLING_EDGE = 2'b10;
    
    // Stage 1: Input synchronization and edge detection
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            sync_reg <= 2'b00;
            edge_valid_stage1 <= 1'b0;
            edge_type_stage1 <= 2'b00;
        end else begin
            sync_reg <= {sync_reg[0], signal_in};
            
            // Detect edges and send to stage1
            edge_valid_stage1 <= (sync_reg[1] != sync_reg[0]);
            
            if (sync_reg == 2'b01) begin
                edge_type_stage1 <= RISING_EDGE;
            end else if (sync_reg == 2'b10) begin
                edge_type_stage1 <= FALLING_EDGE;
            end else begin
                edge_type_stage1 <= 2'b00;
            end
        end
    end
    
    // Stage 2: Pulse generation and width control
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            edge_valid_stage2 <= 1'b0;
            edge_type_stage2 <= 2'b00;
            pulse_counter[0] <= 0;
            pulse_counter[1] <= 0;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
        end else begin
            // Forward pipeline signals
            edge_valid_stage2 <= edge_valid_stage1;
            edge_type_stage2 <= edge_type_stage1;
            
            // Handle rising edge pulse generation
            if (edge_valid_stage2 && (edge_type_stage2 == RISING_EDGE)) begin
                rising_edge <= 1'b1;
                pulse_counter[0] <= PULSE_WIDTH-1;
            end else if (pulse_counter[0] > 0) begin
                pulse_counter[0] <= pulse_counter[0] - 1;
            end else begin
                rising_edge <= 1'b0;
            end
            
            // Handle falling edge pulse generation
            if (edge_valid_stage2 && (edge_type_stage2 == FALLING_EDGE)) begin
                falling_edge <= 1'b1;
                pulse_counter[1] <= PULSE_WIDTH-1;
            end else if (pulse_counter[1] > 0) begin
                pulse_counter[1] <= pulse_counter[1] - 1;
            end else begin
                falling_edge <= 1'b0;
            end
        end
    end
endmodule