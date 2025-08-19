//SystemVerilog
// Top-level 8b10b Encoder Module (Pipelined and Structured Data Path)
module enc_8b10b (
    input              clk,
    input              rst_n,
    input      [7:0]   data_in,
    output reg [9:0]   encoded_out
);

    // Stage 1: Input Register
    reg  [7:0] data_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_stage1 <= 8'd0;
        else
            data_stage1 <= data_in;
    end

    // Stage 2: Control Detection & Data/Control Mapping
    reg        is_control_stage2;
    reg [9:0]  data_encoded_stage2;
    reg [9:0]  ctrl_encoded_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_control_stage2     <= 1'b0;
            data_encoded_stage2   <= 10'd0;
            ctrl_encoded_stage2   <= 10'd0;
        end else begin
            // Control Detection
            is_control_stage2 <= ctrl_detect_func(data_stage1);

            // Data Mapping
            data_encoded_stage2 <= data_map_func(data_stage1);

            // Control Mapping
            ctrl_encoded_stage2 <= ctrl_map_func(data_stage1);
        end
    end

    // Stage 3: Output Mux Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encoded_out <= 10'd0;
        else
            encoded_out <= is_control_stage2 ? ctrl_encoded_stage2 : data_encoded_stage2;
    end

    // Function: Control Detection
    function automatic ctrl_detect_func;
        input [7:0] ctrl_data_in;
        begin
            ctrl_detect_func = (ctrl_data_in == 8'h1C) ? 1'b1 : 1'b0;
        end
    endfunction

    // Function: 8b10b Data Mapping
    function automatic [9:0] data_map_func;
        input [7:0] map_data_in;
        begin
            case(map_data_in)
                8'h00: data_map_func = 10'b1001110100;
                8'h01: data_map_func = 10'b0111010100;
                default: data_map_func = 10'b0000000000;
            endcase
        end
    endfunction

    // Function: 8b10b Control Mapping
    function automatic [9:0] ctrl_map_func;
        input [7:0] ctrl_data_in;
        begin
            case(ctrl_data_in)
                8'h1C: ctrl_map_func = 10'b0011111000;
                default: ctrl_map_func = 10'b0000000000;
            endcase
        end
    endfunction

endmodule