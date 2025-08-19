//SystemVerilog
module shift_shadow_reg #(
    parameter WIDTH = 16,
    parameter STAGES = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shift,
    output wire [WIDTH-1:0] shadow_out
);
    // Shift register chain - registered signals
    reg [WIDTH-1:0] shift_chain [0:STAGES-1];
    
    // Pre-calculated conditions to reduce critical path
    reg shift_en;
    
    // Register the shift enable to reduce fanout and improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_en <= 1'b0;
        end else begin
            shift_en <= shift;
        end
    end
    
    // Distribute shift register across multiple always blocks
    // to break up long logic chains and improve parallelism
    
    // First stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_chain[0] <= {WIDTH{1'b0}};
        end else if (shift_en) begin
            shift_chain[0] <= data_in;
        end
    end
    
    // Middle and final stages
    genvar j;
    generate
        for (j = 1; j < STAGES; j = j + 1) begin : shift_stages
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    shift_chain[j] <= {WIDTH{1'b0}};
                end else if (shift_en) begin
                    shift_chain[j] <= shift_chain[j-1];
                end
            end
        end
    endgenerate
    
    // Last stage is the shadow output
    assign shadow_out = shift_chain[STAGES-1];
endmodule