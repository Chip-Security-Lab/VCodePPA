//SystemVerilog
module load_complete_reg(
    input clk, rst,
    input [15:0] data_in,
    input data_valid,       // Renamed from 'load' to 'data_valid'
    output reg [15:0] data_out,
    output reg data_ready   // Renamed from 'load_done' to 'data_ready'
);
    // Pipeline stage 1 registers
    reg [15:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [15:0] data_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 handshake control
    reg stage3_ready;
    
    // Pipeline stage 1: Input capture with valid signal
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 16'h0;
            valid_stage1 <= 1'b0;
        end else if (data_valid && stage3_ready) begin
            data_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end else if (valid_stage2 && stage3_ready) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Pipeline stage 2: Processing with valid signal propagation
    always @(posedge clk) begin
        if (rst) begin
            data_stage2 <= 16'h0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1 && stage3_ready) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= 1'b1;
        end else if (valid_stage2 && stage3_ready) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Pipeline stage 3: Output generation with ready signal
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'h0;
            data_ready <= 1'b0;
            stage3_ready <= 1'b1;
        end else begin
            if (valid_stage2 && stage3_ready) begin
                data_out <= data_stage2;
                data_ready <= 1'b1;
                stage3_ready <= 1'b0;
            end else begin
                data_ready <= 1'b0;
                stage3_ready <= 1'b1;
            end
        end
    end
endmodule