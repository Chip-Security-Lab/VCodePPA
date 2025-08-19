//SystemVerilog
module nibble_buffer (
    input wire clk,
    input wire rst_n,            // Added reset signal for pipeline control
    input wire [3:0] nibble_in,
    input wire upper_en, lower_en,
    input wire valid_in,         // Input data valid signal
    output wire [7:0] byte_out,
    output wire valid_out,       // Output data valid signal
    output wire ready            // Ready to accept new input
);
    // Stage 1: Input registration
    reg [3:0] nibble_stage1;
    reg upper_en_stage1, lower_en_stage1;
    reg valid_stage1;
    
    // Stage 2: Nibble selection and storage
    reg [3:0] upper_nibble_stage2, lower_nibble_stage2;
    reg upper_valid_stage2, lower_valid_stage2;
    reg valid_stage2;
    
    // Stage 3: Output formation
    reg [7:0] byte_out_stage3;
    reg valid_stage3;
    
    // Pipeline ready signal
    assign ready = 1'b1;  // This design can accept input every cycle
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nibble_stage1 <= 4'b0;
            upper_en_stage1 <= 1'b0;
            lower_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            nibble_stage1 <= nibble_in;
            upper_en_stage1 <= upper_en;
            lower_en_stage1 <= lower_en;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Store nibbles based on enable signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_nibble_stage2 <= 4'b0;
            lower_nibble_stage2 <= 4'b0;
            upper_valid_stage2 <= 1'b0;
            lower_valid_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (upper_en_stage1 && valid_stage1) begin
                upper_nibble_stage2 <= nibble_stage1;
                upper_valid_stage2 <= 1'b1;
            end
            
            if (lower_en_stage1 && valid_stage1) begin
                lower_nibble_stage2 <= nibble_stage1;
                lower_valid_stage2 <= 1'b1;
            end
        end
    end
    
    // Stage 3: Form the final output byte
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_out_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            byte_out_stage3[7:4] <= upper_valid_stage2 ? upper_nibble_stage2 : 4'b0000;
            byte_out_stage3[3:0] <= lower_valid_stage2 ? lower_nibble_stage2 : 4'b0000;
        end
    end
    
    // Connect final stage to outputs
    assign byte_out = byte_out_stage3;
    assign valid_out = valid_stage3;
    
endmodule