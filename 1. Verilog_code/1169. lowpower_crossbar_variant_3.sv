//SystemVerilog
module lowpower_crossbar (
    input  wire        clk,      // System clock
    input  wire        rst_n,    // Active low reset
    input  wire [63:0] in_data,  // Input data array
    input  wire [7:0]  out_sel,  // Output selection control
    input  wire [3:0]  in_valid, // Input valid signals
    output reg  [63:0] out_data  // Output data array
);
    // ========== Stage 1: Input Capture and Validation ==========
    reg [63:0] in_data_r;
    reg [7:0]  out_sel_r;
    reg [3:0]  in_valid_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_r  <= 64'h0;
            out_sel_r  <= 8'h0;
            in_valid_r <= 4'h0;
        end else begin
            // Only capture inputs when at least one input is valid
            if (|in_valid) begin
                in_data_r  <= in_data;
                out_sel_r  <= out_sel;
                in_valid_r <= in_valid;
            end
        end
    end
    
    // ========== Stage 2: Routing Control Logic ==========
    // Route mapping signals - indicate which input goes to which output
    wire [3:0] route_map [0:3]; // [output][input]
    
    // Expanded genvar loops for output 0
    assign route_map[0][0] = in_valid_r[0] && (out_sel_r[0*2+:2] == 0);
    assign route_map[0][1] = in_valid_r[1] && (out_sel_r[1*2+:2] == 0);
    assign route_map[0][2] = in_valid_r[2] && (out_sel_r[2*2+:2] == 0);
    assign route_map[0][3] = in_valid_r[3] && (out_sel_r[3*2+:2] == 0);
    
    // Expanded genvar loops for output 1
    assign route_map[1][0] = in_valid_r[0] && (out_sel_r[0*2+:2] == 1);
    assign route_map[1][1] = in_valid_r[1] && (out_sel_r[1*2+:2] == 1);
    assign route_map[1][2] = in_valid_r[2] && (out_sel_r[2*2+:2] == 1);
    assign route_map[1][3] = in_valid_r[3] && (out_sel_r[3*2+:2] == 1);
    
    // Expanded genvar loops for output 2
    assign route_map[2][0] = in_valid_r[0] && (out_sel_r[0*2+:2] == 2);
    assign route_map[2][1] = in_valid_r[1] && (out_sel_r[1*2+:2] == 2);
    assign route_map[2][2] = in_valid_r[2] && (out_sel_r[2*2+:2] == 2);
    assign route_map[2][3] = in_valid_r[3] && (out_sel_r[3*2+:2] == 2);
    
    // Expanded genvar loops for output 3
    assign route_map[3][0] = in_valid_r[0] && (out_sel_r[0*2+:2] == 3);
    assign route_map[3][1] = in_valid_r[1] && (out_sel_r[1*2+:2] == 3);
    assign route_map[3][2] = in_valid_r[2] && (out_sel_r[2*2+:2] == 3);
    assign route_map[3][3] = in_valid_r[3] && (out_sel_r[3*2+:2] == 3);
    
    // ========== Stage 3: Data Path Selection and Segment Generation ==========
    reg [15:0] segment_data [0:3];
    reg [3:0]  segment_valid;
    
    // Expanded integer loop for segment 0
    always @(*) begin
        segment_data[0] = 16'h0;
        segment_valid[0] = 1'b0;
        
        // Priority encoder for output segment 0
        if (route_map[0][0]) begin
            segment_data[0] = in_data_r[15:0];
            segment_valid[0] = 1'b1;
        end else if (route_map[0][1]) begin
            segment_data[0] = in_data_r[31:16];
            segment_valid[0] = 1'b1;
        end else if (route_map[0][2]) begin
            segment_data[0] = in_data_r[47:32];
            segment_valid[0] = 1'b1;
        end else if (route_map[0][3]) begin
            segment_data[0] = in_data_r[63:48];
            segment_valid[0] = 1'b1;
        end
    end
    
    // Expanded integer loop for segment 1
    always @(*) begin
        segment_data[1] = 16'h0;
        segment_valid[1] = 1'b0;
        
        // Priority encoder for output segment 1
        if (route_map[1][0]) begin
            segment_data[1] = in_data_r[15:0];
            segment_valid[1] = 1'b1;
        end else if (route_map[1][1]) begin
            segment_data[1] = in_data_r[31:16];
            segment_valid[1] = 1'b1;
        end else if (route_map[1][2]) begin
            segment_data[1] = in_data_r[47:32];
            segment_valid[1] = 1'b1;
        end else if (route_map[1][3]) begin
            segment_data[1] = in_data_r[63:48];
            segment_valid[1] = 1'b1;
        end
    end
    
    // Expanded integer loop for segment 2
    always @(*) begin
        segment_data[2] = 16'h0;
        segment_valid[2] = 1'b0;
        
        // Priority encoder for output segment 2
        if (route_map[2][0]) begin
            segment_data[2] = in_data_r[15:0];
            segment_valid[2] = 1'b1;
        end else if (route_map[2][1]) begin
            segment_data[2] = in_data_r[31:16];
            segment_valid[2] = 1'b1;
        end else if (route_map[2][2]) begin
            segment_data[2] = in_data_r[47:32];
            segment_valid[2] = 1'b1;
        end else if (route_map[2][3]) begin
            segment_data[2] = in_data_r[63:48];
            segment_valid[2] = 1'b1;
        end
    end
    
    // Expanded integer loop for segment 3
    always @(*) begin
        segment_data[3] = 16'h0;
        segment_valid[3] = 1'b0;
        
        // Priority encoder for output segment 3
        if (route_map[3][0]) begin
            segment_data[3] = in_data_r[15:0];
            segment_valid[3] = 1'b1;
        end else if (route_map[3][1]) begin
            segment_data[3] = in_data_r[31:16];
            segment_valid[3] = 1'b1;
        end else if (route_map[3][2]) begin
            segment_data[3] = in_data_r[47:32];
            segment_valid[3] = 1'b1;
        end else if (route_map[3][3]) begin
            segment_data[3] = in_data_r[63:48];
            segment_valid[3] = 1'b1;
        end
    end
    
    // ========== Stage 4: Output Register with Clock Gating Control ==========
    // Clock gating control signals - more fine-grained than original
    wire [3:0] segment_update;
    
    // Expanded genvar loop for clock gating
    assign segment_update[0] = segment_valid[0];
    assign segment_update[1] = segment_valid[1];
    assign segment_update[2] = segment_valid[2];
    assign segment_update[3] = segment_valid[3];
    
    // Output registers with segment-specific clock gating
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 64'h0;
        end else begin
            // Use segment-specific clock gating for power optimization
            if (segment_update[0]) out_data[15:0]   <= segment_data[0];
            if (segment_update[1]) out_data[31:16]  <= segment_data[1];
            if (segment_update[2]) out_data[47:32]  <= segment_data[2];
            if (segment_update[3]) out_data[63:48]  <= segment_data[3];
        end
    end
    
endmodule