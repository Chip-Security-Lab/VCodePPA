//SystemVerilog IEEE 1364-2005
module param_crossbar #(
    parameter PORTS = 4,
    parameter WIDTH = 8
)(
    input wire clock, reset,
    input wire [WIDTH-1:0] in [0:PORTS-1],
    input wire [$clog2(PORTS)-1:0] sel [0:PORTS-1],
    input wire enable,
    output reg [WIDTH-1:0] out [0:PORTS-1]
);
    // Stage 1: Input selection and registering
    reg [WIDTH-1:0] stage1_data [0:PORTS-1];
    reg stage1_valid;
    reg [$clog2(PORTS)-1:0] stage1_sel [0:PORTS-1];
    
    // Stage 2: Processing selected data
    reg [WIDTH-1:0] stage2_data [0:PORTS-1];
    reg stage2_valid;
    
    integer i;
    
    // Stage 1: Register inputs and selection signals
    always @(posedge clock) begin
        if (reset) begin
            stage1_valid <= 1'b0;
            for (i = 0; i < PORTS; i = i + 1) begin
                stage1_data[i] <= {WIDTH{1'b0}};
                stage1_sel[i] <= {$clog2(PORTS){1'b0}};
            end
        end else begin
            stage1_valid <= enable;
            for (i = 0; i < PORTS; i = i + 1) begin
                stage1_data[i] <= in[i];
                stage1_sel[i] <= sel[i];
            end
        end
    end
    
    // Stage 2: Select correct input data based on selection signals
    always @(posedge clock) begin
        if (reset) begin
            stage2_valid <= 1'b0;
            for (i = 0; i < PORTS; i = i + 1) begin
                stage2_data[i] <= {WIDTH{1'b0}};
            end
        end else begin
            stage2_valid <= stage1_valid;
            for (i = 0; i < PORTS; i = i + 1) begin
                if (stage1_valid) begin
                    stage2_data[i] <= stage1_data[stage1_sel[i]];
                end else begin
                    stage2_data[i] <= stage2_data[i];
                end
            end
        end
    end
    
    // Final stage: Output registers
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < PORTS; i = i + 1) begin
                out[i] <= {WIDTH{1'b0}};
            end
        end else begin
            for (i = 0; i < PORTS; i = i + 1) begin
                if (stage2_valid) begin
                    out[i] <= stage2_data[i];
                end else begin
                    out[i] <= out[i];
                end
            end
        end
    end
endmodule