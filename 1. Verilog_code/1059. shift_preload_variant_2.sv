//SystemVerilog
module shift_preload_pipeline #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input                   load,
    input  [WIDTH-1:0]      load_data,
    input                   valid_in,
    output                  ready_out,
    output reg [WIDTH-1:0]  sr_out,
    output                  valid_out
);

    // Stage 1: Combinational logic for shift/load selection
    reg [WIDTH-1:0] sr_next;
    reg             valid_next;

    always @(*) begin
        case (load)
            1'b1: sr_next = load_data;
            1'b0: sr_next = {sr_out[WIDTH-2:0], 1'b0};
            default: sr_next = {WIDTH{1'b0}};
        endcase
        valid_next = valid_in;
    end

    // Stage 2: Registers after combinational logic
    reg [WIDTH-1:0] sr_stage2;
    reg             valid_stage2;

    // Ready/Valid logic
    assign ready_out = 1'b1; // Always ready to accept new data
    assign valid_out = valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sr_stage2    <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (ready_out) begin
                sr_stage2    <= sr_next;
                valid_stage2 <= valid_next;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sr_out <= {WIDTH{1'b0}};
        end else if (valid_stage2) begin
            sr_out <= sr_stage2;
        end
    end

endmodule