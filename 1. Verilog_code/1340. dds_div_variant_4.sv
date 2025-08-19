//SystemVerilog - IEEE 1364-2005
module dds_div #(parameter FTW=32'h19999999) (
    input wire clk,
    input wire rst,
    input wire enable,    // Added enable signal for pipeline control
    output wire clk_out,
    output wire valid_out // Added valid signal to indicate valid output
);
    // Pipeline stage signals
    wire [31:0] phase_acc_stage1;
    wire valid_stage1;
    
    // Instantiate phase accumulator submodule (first pipeline stage)
    phase_accumulator #(
        .FTW(FTW)
    ) phase_acc_inst (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .phase_acc(phase_acc_stage1),
        .valid_out(valid_stage1)
    );
    
    // Instantiate clock generation submodule (second pipeline stage)
    clock_generator clock_gen_inst (
        .clk(clk),
        .rst(rst),
        .enable(valid_stage1), // Connect to previous stage valid signal
        .phase_msb(phase_acc_stage1[31]),
        .clk_out(clk_out),
        .valid_out(valid_out)
    );
    
endmodule

// Phase accumulator module - first pipeline stage
module phase_accumulator #(parameter FTW=32'h19999999) (
    input wire clk,
    input wire rst,
    input wire enable,
    output reg [31:0] phase_acc,
    output reg valid_out
);
    // Internal pipeline registers
    reg enable_r;
    
    // Pipeline stage 1: Register enable signal
    always @(posedge clk) begin
        if (rst) begin
            enable_r <= 1'b0;
        end else begin
            enable_r <= enable;
        end
    end
    
    // Pipeline stage 2: Accumulate phase when enabled
    always @(posedge clk) begin
        if (rst) begin
            phase_acc <= 32'b0;
            valid_out <= 1'b0;
        end else if (enable_r) begin
            phase_acc <= phase_acc + FTW;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
    
endmodule

// Clock generation module - second pipeline stage
module clock_generator (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire phase_msb,
    output reg clk_out,
    output reg valid_out
);
    // Internal pipeline registers
    reg phase_msb_r;
    reg enable_r;
    
    // Pipeline stage 1: Register input values
    always @(posedge clk) begin
        if (rst) begin
            phase_msb_r <= 1'b0;
            enable_r <= 1'b0;
        end else begin
            phase_msb_r <= phase_msb;
            enable_r <= enable;
        end
    end
    
    // Pipeline stage 2: Generate output clock
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
            valid_out <= 1'b0;
        end else if (enable_r) begin
            clk_out <= phase_msb_r;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
    
endmodule