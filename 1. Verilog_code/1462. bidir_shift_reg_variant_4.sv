//SystemVerilog
module bidir_shift_reg(
    input clock, clear,
    input [7:0] p_data,
    input load, shift, dir, s_in,
    input valid_in,
    output reg valid_out,
    output reg [7:0] q
);
    // Forward retimed registers structure
    // First stage: Direct input handling without additional registers
    wire [7:0] p_data_w;
    wire load_w, shift_w, dir_w, s_in_w, valid_w;
    
    assign p_data_w = p_data;
    assign load_w = load;
    assign shift_w = shift;
    assign dir_w = dir;
    assign s_in_w = s_in;
    assign valid_w = valid_in;
    
    // Stage 2: Operation logic with registered outputs
    reg [7:0] data_r1;
    reg valid_r1;
    
    always @(posedge clock) begin
        if (clear) begin
            data_r1 <= 8'b0;
            valid_r1 <= 1'b0;
        end else begin
            valid_r1 <= valid_w;
            
            // Priority-encoded operation selection
            if (load_w)
                data_r1 <= p_data_w;
            else if (shift_w) begin
                // Parameterized shift operation
                data_r1 <= dir_w ? {s_in_w, q[7:1]} : {q[6:0], s_in_w};
            end else
                data_r1 <= q;
        end
    end
    
    // Stage 3: Intermediate processing stage
    reg [7:0] result_r2;
    reg valid_r2;
    
    always @(posedge clock) begin
        if (clear) begin
            result_r2 <= 8'b0;
            valid_r2 <= 1'b0;
        end else begin
            result_r2 <= data_r1;
            valid_r2 <= valid_r1;
        end
    end
    
    // Final output assignment
    always @(posedge clock) begin
        if (clear) begin
            q <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            q <= result_r2;
            valid_out <= valid_r2;
        end
    end
endmodule