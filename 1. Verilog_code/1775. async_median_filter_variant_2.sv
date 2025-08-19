//SystemVerilog
module async_median_filter #(
    parameter W = 16
)(
    input [W-1:0] a, b, c,
    output [W-1:0] med_out
);
    // Parallel prefix subtractor signals
    wire [W-1:0] a_comp, b_comp;
    wire [W-1:0] diff_ab, diff_ba;
    wire [W-1:0] min_ab, max_ab;
    wire [W-1:0] result;
    
    // Generate propagate and generate signals
    wire [W-1:0] p_ab, g_ab;
    wire [W-1:0] p_ba, g_ba;
    
    // Parallel prefix tree signals
    wire [W-1:0] p_tree_ab[0:3], g_tree_ab[0:3];
    wire [W-1:0] p_tree_ba[0:3], g_tree_ba[0:3];
    
    // Generate propagate and generate terms
    assign p_ab = a ^ b;
    assign g_ab = a & b;
    assign p_ba = b ^ a;
    assign g_ba = b & a;
    
    // First level of prefix tree
    assign p_tree_ab[0] = p_ab;
    assign g_tree_ab[0] = g_ab;
    assign p_tree_ba[0] = p_ba;
    assign g_tree_ba[0] = g_ba;
    
    // Second level of prefix tree
    assign p_tree_ab[1] = p_tree_ab[0][7:4] & p_tree_ab[0][3:0];
    assign g_tree_ab[1] = (p_tree_ab[0][7:4] & g_tree_ab[0][3:0]) | g_tree_ab[0][7:4];
    assign p_tree_ba[1] = p_tree_ba[0][7:4] & p_tree_ba[0][3:0];
    assign g_tree_ba[1] = (p_tree_ba[0][7:4] & g_tree_ba[0][3:0]) | g_tree_ba[0][7:4];
    
    // Third level of prefix tree
    assign p_tree_ab[2] = p_tree_ab[1][7:6] & p_tree_ab[1][5:4];
    assign g_tree_ab[2] = (p_tree_ab[1][7:6] & g_tree_ab[1][5:4]) | g_tree_ab[1][7:6];
    assign p_tree_ba[2] = p_tree_ba[1][7:6] & p_tree_ba[1][5:4];
    assign g_tree_ba[2] = (p_tree_ba[1][7:6] & g_tree_ba[1][5:4]) | g_tree_ba[1][7:6];
    
    // Final level of prefix tree
    assign p_tree_ab[3] = p_tree_ab[2][7] & p_tree_ab[2][6];
    assign g_tree_ab[3] = (p_tree_ab[2][7] & g_tree_ab[2][6]) | g_tree_ab[2][7];
    assign p_tree_ba[3] = p_tree_ba[2][7] & p_tree_ba[2][6];
    assign g_tree_ba[3] = (p_tree_ba[2][7] & g_tree_ba[2][6]) | g_tree_ba[2][7];
    
    // Generate final difference
    assign diff_ab = p_ab ^ {g_tree_ab[3], g_tree_ab[2][5:4], g_tree_ab[1][3:0]};
    assign diff_ba = p_ba ^ {g_tree_ba[3], g_tree_ba[2][5:4], g_tree_ba[1][3:0]};
    
    // Select min and max based on MSB of difference
    assign min_ab = diff_ab[W-1] ? b : a;
    assign max_ab = diff_ab[W-1] ? a : b;
    
    // Compare with c using parallel prefix subtractor
    wire [W-1:0] p_c_min, g_c_min;
    wire [W-1:0] p_c_max, g_c_max;
    wire [W-1:0] diff_c_min, diff_c_max;
    
    assign p_c_min = c ^ min_ab;
    assign g_c_min = c & min_ab;
    assign p_c_max = c ^ max_ab;
    assign g_c_max = c & max_ab;
    
    // Parallel prefix tree for c comparison
    wire [W-1:0] p_tree_c_min[0:3], g_tree_c_min[0:3];
    wire [W-1:0] p_tree_c_max[0:3], g_tree_c_max[0:3];
    
    // First level
    assign p_tree_c_min[0] = p_c_min;
    assign g_tree_c_min[0] = g_c_min;
    assign p_tree_c_max[0] = p_c_max;
    assign g_tree_c_max[0] = g_c_max;
    
    // Second level
    assign p_tree_c_min[1] = p_tree_c_min[0][7:4] & p_tree_c_min[0][3:0];
    assign g_tree_c_min[1] = (p_tree_c_min[0][7:4] & g_tree_c_min[0][3:0]) | g_tree_c_min[0][7:4];
    assign p_tree_c_max[1] = p_tree_c_max[0][7:4] & p_tree_c_max[0][3:0];
    assign g_tree_c_max[1] = (p_tree_c_max[0][7:4] & g_tree_c_max[0][3:0]) | g_tree_c_max[0][7:4];
    
    // Third level
    assign p_tree_c_min[2] = p_tree_c_min[1][7:6] & p_tree_c_min[1][5:4];
    assign g_tree_c_min[2] = (p_tree_c_min[1][7:6] & g_tree_c_min[1][5:4]) | g_tree_c_min[1][7:6];
    assign p_tree_c_max[2] = p_tree_c_max[1][7:6] & p_tree_c_max[1][5:4];
    assign g_tree_c_max[2] = (p_tree_c_max[1][7:6] & g_tree_c_max[1][5:4]) | g_tree_c_max[1][7:6];
    
    // Final level
    assign p_tree_c_min[3] = p_tree_c_min[2][7] & p_tree_c_min[2][6];
    assign g_tree_c_min[3] = (p_tree_c_min[2][7] & g_tree_c_min[2][6]) | g_tree_c_min[2][7];
    assign p_tree_c_max[3] = p_tree_c_max[2][7] & p_tree_c_max[2][6];
    assign g_tree_c_max[3] = (p_tree_c_max[2][7] & g_tree_c_max[2][6]) | g_tree_c_max[2][7];
    
    // Generate final differences
    assign diff_c_min = p_c_min ^ {g_tree_c_min[3], g_tree_c_min[2][5:4], g_tree_c_min[1][3:0]};
    assign diff_c_max = p_c_max ^ {g_tree_c_max[3], g_tree_c_max[2][5:4], g_tree_c_max[1][3:0]};
    
    // Select median based on comparison results
    assign result = diff_c_min[W-1] ? min_ab : 
                   (diff_c_max[W-1] ? c : max_ab);
    
    assign med_out = result;
endmodule