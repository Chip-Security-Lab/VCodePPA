//SystemVerilog
module shift_dynamic_cfg #(parameter WIDTH=8) (
    input                  clk,
    input                  rst_n,
    input                  in_valid,
    input  [1:0]           cfg_mode,
    input  [WIDTH-1:0]     cfg_data,
    output                 out_valid,
    output [WIDTH-1:0]     dout
);

    // Stage 1: Capture inputs and decode mode
    reg [1:0]              mode_stage1;
    reg [WIDTH-1:0]        data_stage1;
    reg [WIDTH-1:0]        prev_dout_stage1;
    reg                    valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode_stage1       <= 2'b00;
            data_stage1       <= {WIDTH{1'b0}};
            prev_dout_stage1  <= {WIDTH{1'b0}};
            valid_stage1      <= 1'b0;
        end else begin
            if (in_valid) begin
                mode_stage1      <= cfg_mode;
                data_stage1      <= cfg_data;
                prev_dout_stage1 <= dout_out;
                valid_stage1     <= 1'b1;
            end else begin
                valid_stage1     <= 1'b0;
            end
        end
    end

    // Stage 2: Optimized Shift/Load operation
    reg [WIDTH-1:0]        dout_stage2;
    reg                    valid_stage2;

    wire is_shift_left  = (mode_stage1 == 2'b01);
    wire is_shift_right = (mode_stage1 == 2'b10);
    wire is_load        = (mode_stage1 == 2'b11);
    wire is_hold        = (mode_stage1 == 2'b00);

    wire [WIDTH-1:0] shift_left_result  = {prev_dout_stage1[WIDTH-2:0], 1'b0};
    wire [WIDTH-1:0] shift_right_result = {1'b0, prev_dout_stage1[WIDTH-1:1]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2  <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                dout_stage2 <= is_shift_left  ? shift_left_result  :
                               is_shift_right ? shift_right_result :
                               is_load        ? data_stage1        :
                                                prev_dout_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end

    // Output register
    reg [WIDTH-1:0]        dout_out;
    reg                    valid_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                dout_out  <= dout_stage2;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

    assign dout      = dout_out;
    assign out_valid = valid_out;

endmodule